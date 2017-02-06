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

  def self.get_configlets
    response = api.get_configlets
    return [] if !response || response.empty?
    configlet = {}
    response['data'].each do |data|
      configlet[data['name']] = { content: data['config'].strip }
    end
    configlet
  end

  def self.instances
    configlets = get_configlets
    return [] if !configlets || configlets.empty?
    Puppet.debug "configlet_instances: #{configlets.inspect}"
    configlets.map do |name, attrs|
      provider_hash = { name: name, ensure: :present,
                        content: attrs[:content] }
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

  def content=(_value)
    # @property_flush[:content] = value
    configlet = api.get_configlet_by_name(resource[:name])
    task_id = api.update_configlet(resource[:name],
                                   configlet['key'],
                                   resource[:content])
  end

  def create
    cfglt_id = api.add_configlet(resource[:name],
                                 resource[:content])
    raise "Failed to create configlet #{resource[:name]}" if cfglt_id.empty?
    Puppet.debug "CVP configlet [#{cfglt_id}] was created.  Auto_run set to #{auto_run}"
    # require 'pry'
    # binding.pry
    if resource.auto_run?
      task_id = nil # TODO: get form CVP
      result = api.execute_task(task_id)
      Puppet.debug "CVP task [#{task_id}] returned status: #{result}"
    end
    @property_hash = { name: resource[:name],
                       content: resource[:content] }
  end

  def destroy
    configlet = api.get_configlet_by_name(resource[:name])
    # TODO: get all associates nodes/containers so we can re-apply their configs
    status = api.delete_configlet(resource[:name], configlet['key'])
    raise "Failed to delete configlet #{resource[:name]}" if status != 'success'
    Puppet.debug "CVP task [#{resource[:name]}] was deleted.  Auto_run set to #{auto_run}"
    # require 'pry'
    # binding.pry
    # if auto_run?
    #  result = api.execute_task(task_id)
    #  Puppet.debug "CVP task [#{task_id}] returned status: #{result}"
    # end
    @property_hash = { name: resource[:name], ensure: :absent }
  end

  # def flush
  #  Puppet.debug "Updating configlet: #{resource[:name]}"
  #  @property_hash.merge!(@property_flush)

  #  # TODO: Do we need to know the node to which to assign a configlet, if we
  #  # can't assume the blank configlet was pre-created?

  #  task_id = api.set_configlet_content(@property_hash[:name],
  #                                      @property_hash[:content])
  #  raise "Failed to set configlet #{@property_hash[:name]} content" if task_id.empty?
  #  Puppet.debug "CVP task [#{task_id}] was created.  Auto_run set to "\
  #    "#{auto_run}"
  #  if resource.auto_run?
  #    result = api.execute_task(task_id)
  #    Puppet.debug "CVP task [#{task_id}] returned status: #{result}"
  #  end
  #  #api.execute_task(task_id) if @property_hash[:auto_run] == :true

  #  @property_flush = {}
  # end
end
