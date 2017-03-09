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

Puppet::Type.type(:cloudvision_configlet).provide(:cloudvision) do
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
    configlets = get_configlets
    return [] if !configlets || configlets.empty?
    Puppet.debug "configlet_instances: #{configlets.inspect}"
    configlets.map do |name, attrs|
      provider_hash = { name: name, ensure: :present,
                        content: attrs[:content],
                        containers: attrs[:containers] }
      new(provider_hash)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  # def auto_run=(value)
  #  @property_flush[:auto_run] = value
  # end

  def handle_tasks(task_ids)
    task_ids = Array(task_ids) # Ensure array even if given a single string
    Puppet.debug "CVP handle_tasks auto_run: #{resource.auto_run?}"\
                 ", task_ids: #{task_ids}"
    return unless resource.auto_run?
    task_ids.each do |task_id|
      result = api.execute_task(task_id)
      Puppet.debug "CVP task [#{task_id}] started with info: #{result['data']}"
      status = { 'taskStatus' => nil }
      while status['taskStatus'] != 'COMPLETED'
        status = api.get_task_by_id(task_id)
        Puppet.debug "CVP task [#{task_id}] returned"\
                     " status: #{status['taskStatus']}"
        sleep 3
      end
    end
  end

  def content=(_value)
    configlet = api.get_configlet_by_name(resource[:name])
    api.update_configlet(resource[:name],
                         configlet['key'],
                         resource[:content])
    tasks = api.get_pending_tasks_by_device(resource[:name])
    task_ids = tasks.map { |task| task['workOrderId'] } || []
    handle_tasks(task_ids)
  end

  def add_configlet_to_element(dev)
    net_elem = api.get_device_by_name(dev)
    Puppet.debug "CVP device #{dev} has outstanding tasks before configlet"\
                 ' is added.' unless net_elem['taskIdList'].length.zero?

    # Add configlet to nodes
    configlet = api.get_configlet_by_name(resource[:name])
    apply = api.apply_configlets_to_device('Puppet Assign Host Port Configlet',
                                           net_elem,
                                           [{ 'name' => configlet['name'],
                                              'key' => configlet['key'] }])
    handle_tasks(apply['data']['taskIds']) if apply['data'].key?('taskIds')
  end

  def remove_configlet_from_element(dev)
    net_elem = api.get_device_by_name(dev)
    Puppet.debug "CVP device #{dev} has outstanding tasks before configlet is"\
                 ' added.' unless net_elem['taskIdList'].length.zero?

    # Add configlet to nodes
    configlet = api.get_configlet_by_name(resource[:name])
    apply = api.remove_configlets_from_device('Puppet Remove Host Port Configlet',
                                              net_elem,
                                              [{ 'name' => configlet['name'],
                                                 'key' => configlet['key'] }])
    handle_tasks(apply['data']['taskIds']) if apply['data'].key?('taskIds')
  end

  def containers=(_value)
    removes = @property_hash[:containers] - @resource[:containers]
    adds = @resource[:containers] - @property_hash[:containers]

    removes.each do |dev|
      remove_configlet_from_element(dev)
    end

    adds.each do |dev|
      add_configlet_to_element(dev)
    end
  end

  def create
    cfglt_id = api.add_configlet(resource[:name],
                                 resource[:content])
    raise "Failed to create configlet #{resource[:name]}" if cfglt_id.empty?
    Puppet.debug "CVP configlet [#{cfglt_id}] was created.  Auto_run set"\
                 " to #{auto_run}"
    @resource[:containers].each do |dev|
      add_configlet_to_element(dev)
    end

    @property_hash = { name: resource[:name],
                       content: resource[:content] }
  end

  def destroy
    configlet = api.get_configlet_by_name(resource[:name])
    if configlet['netElementCount'] > 0
      # Get the network elements
      devices = api.get_devices_by_configlet_name(resource[:name])
      # require 'pry'
      # binding.pry
      devices['data'].each do |dev|
        remove_configlet_from_element(dev['hostName'])
      end
    end
    status = api.delete_configlet(resource[:name], configlet['key'])
    raise "Failed to delete configlet #{resource[:name]}" if status != 'success'
    Puppet.debug "CVP task [#{resource[:name]}] was deleted."\
                 "  Auto_run set to #{auto_run}"
    @property_hash = { name: resource[:name], ensure: :absent }
  end
end
