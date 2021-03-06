# Copyright (c) 2017, Arista Networks EOS+
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of Arista Networks nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'puppet/type'
require 'pathname'

module_lib = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/cloudvision/provider'

Puppet::Type.type(:cloudvision_configlet).provide(:default) do
  desc 'Manage configlet content on Arista CloudVision.  Requires cvprac rubygem.'

  confine feature: :cvprac

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Cloudvision::RacProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Cloudvision::RacProviderMixin

  # rubocop:disable Style/AccessorMethodName
  def self.get_configlets
    response = api.get_configlets
    return [] if !response || response.empty?
    configlet = {}
    response['data'].each do |data|
      configlet[data['name']] = { content: data['config'].strip }
      devices = api.get_devices_by_configlet_name(data['name'])
      containers = devices['data'].map { |dev| dev['hostName'] } || []
      configlet[data['name']][:containers] = containers
    end
    configlet
  end
  # rubocop:enable Style/AccessorMethodName

  def self.instances
    # Unable to access API credentials at this point
  end

  def exists?
    begin
      @configlet = api.get_configlet_by_name(resource[:name])
    rescue CvpApiError
      # CvpApiError: ERROR: get
      #   /web/configlet/getConfigletByName.do?name=fred:: Request Error:
      #   errorCode: 132801: Entity does not exist
      return false
    end
    return false unless @configlet
    return true if @configlet['name'] == resource[:name]
    false
  end

  def handle_tasks(task_ids, timeout = 300)
    # Task workOrderUserDefinedStatus states:
    #   Pending
    #   In-Progress
    #   FailedCompleted
    #   Cancelled
    #   Waiting for Reboot
    #   Device Reboot in Progress
    #   Configlet Push In Progress
    #   Task Update In Progress
    #   Completed
    #
    task_ids = Array(task_ids) # Ensure array even if given a single string
    Puppet.debug "CVP handle_tasks(ids): #{task_ids}"
    task_ids.each do |task_id|
      result = api.execute_task(task_id)
      Puppet.debug "CVP task #{task_id} started with info: #{result['data']}"
      now = started = Time.now
      state = nil
      while state != 'Completed'
        status = api.get_task_by_id(task_id)
        state  = status['workOrderUserDefinedStatus']
        Puppet.debug "CVP task #{task_id} returned status: #{state}"

        if state == 'FailedCompleted' || state == 'Cancelled'
          raise("CVP task did not complete successfully: #{state}")
        end

        # rubocop:disable Style/GuardClause
        if now < started + timeout
          sleep 3
          now = Time.now
        else
          raise("CVP module timed out while task still in '#{state}' state: now [#{now}] | Started: [#{started}]")
        end
        # rubocop:enable Style/GuardClause
      end
      Puppet.info "CVP task #{task_id} status: #{state}"
    end
  end

  def add_configlet_to_element(dev, timeout = 300, auto_run = false)
    net_elem = api.get_device_by_name(dev)
    unless net_elem['taskIdList'].length.zero?
      Puppet.debug "CVP device #{dev} has outstanding tasks before configlet"\
                   ' is added.'
    end

    # Add configlet to nodes
    configlet = api.get_configlet_by_name(resource[:name])
    apply = api.apply_configlets_to_device('Puppet Assign Host Port Configlet',
                                           net_elem,
                                           [{ 'name' => configlet['name'],
                                              'key' => configlet['key'] }])
    tasks = apply['data']['taskIds'] if apply['data'].key?('taskIds')
    handle_tasks(tasks, timeout) if tasks && auto_run
  end

  def remove_configlet_from_element(dev, timeout = 300, auto_run = false)
    net_elem = api.get_device_by_name(dev)
    unless net_elem['taskIdList'].length.zero?
      Puppet.warning "CVP device #{dev} has outstanding tasks before configlet"\
                   ' is removed.'
      raise "CVP device #{dev} cannot be removed with outstanding tasks."
    end

    # Add configlet to nodes
    configlet = api.get_configlet_by_name(resource[:name])
    apply = api.remove_configlets_from_device('Puppet Remove Host Port Configlet',
                                              net_elem,
                                              [{ 'name' => configlet['name'],
                                                 'key' => configlet['key'] }])
    tasks = apply['data'].key?('taskIds') ? apply['data']['taskIds'] : nil
    handle_tasks(tasks, timeout) if tasks && auto_run
  end

  def create
    cfglt_id = api.add_configlet(resource[:name],
                                 resource[:content])
    raise "Failed to create configlet #{resource[:name]}" if cfglt_id.empty?
    Puppet.debug "CVP configlet [#{cfglt_id}] was created.  Auto_run set"\
                 " to #{auto_run}"
    @resource[:containers].each do |dev|
      add_configlet_to_element(dev, resource[:timeout], resource[:auto_run])
    end

    @property_hash = { name: resource[:name],
                       auto_run: resource[:auto_run],
                       containers: resource[:containers],
                       content: resource[:content],
                       ensure: :present }
  end

  def content
    # @configlet populated in exists? method
    return nil unless @configlet
    @configlet['config'].strip
  end

  def containers
    devices = api.get_devices_by_configlet_name(resource[:name])
    containers = devices['data'].map { |dev| dev['hostName'] } || []
    containers
  end

  def containers=(value)
    removes = value - @resource[:containers]
    adds = @resource[:containers] - value

    removes.each do |dev|
      remove_configlet_from_element(dev, resource[:timeout])
    end

    adds.each do |dev|
      add_configlet_to_element(dev, resource[:timeout], resource[:auto_run])
    end

    @property_hash[:containers] = value
  end

  def content=(value)
    configlet = api.get_configlet_by_name(resource[:name])
    api.update_configlet(resource[:name],
                         configlet['key'],
                         value)
    tasks = api.get_pending_tasks_by_device(resource[:name])
    task_ids = tasks.map { |task| task['workOrderId'] } || []
    Puppet.info "CVP generated task #{task_ids}."\
                 "  Auto_run set to #{resource[:auto_run]}"
    handle_tasks(task_ids, resource[:timeout]) if resource[:auto_run]
    @property_hash[:content] = value
  end

  def destroy
    configlet = api.get_configlet_by_name(resource[:name])
    if configlet['netElementCount'] > 0
      hosts = []
      # Get the network elements
      devices = api.get_devices_by_configlet_name(resource[:name])
      devices['data'].each do |dev|
        remove_configlet_from_element(dev['hostName'],
                                      resource[:timeout],
                                      resource[:auto_run])
        hosts << dev['hostName']
      end
      Puppet.debug "Removed configlet #{resource[:name]} from #{hosts}."\
    end
    begin
      status = api.delete_configlet(resource[:name], configlet['key'])
    rescue
      raise "Failed to delete configlet #{resource[:name]}: #{status}"
    end
    raise "Failed to delete configlet #{resource[:name]}" if status != 'success'
    Puppet.debug "CVP configlet #{resource[:name]} was removed."\
                 "  Auto_run set to #{resource[:auto_run]}"
    @property_hash = { name: resource[:name],
                       ensure: :absent }
  end
end
