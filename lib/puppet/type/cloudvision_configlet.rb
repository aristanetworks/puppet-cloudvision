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

require 'puppet/parameter/boolean'

Puppet::Type.newtype(:cloudvision_configlet) do
  @doc = <<-EOS
    Manage the content of a configlet in Arista CloudVision. If :auto_run is
    :true, the associated, generated CV task will be run immediately.

    Examples:

        $config = 'interface Ethernet2
           description ESX Host 3-2 vnic0
           switchport mode trunk
           switchport trunk vlan allowed 200-300
           no shutdown'

        cloudvision_configlet { 'rack3-tor-Ethernet2':
          ensure     => present,
          cvp_nodes  => ['cvp1', 'cvp2', 'cvp3'],
          cvp_user   => 'puppet_cvp_user',
          cvp_pass   => 'cvp_password',
          content    => $config,
          containers => ['fqdn-1', ..., 'fqdn-N'],
          auto_run   => true,
          timeout    => 600,
        }
  EOS

  ensurable

  autorequire(:package) do
    ['cvprac']
  end

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter is the name of the configlet to manage
    EOS

    validate do |value|
      unless value.is_a? String
        raise "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newparam(:auto_run, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc <<-EOS
      Should the module automatically, immediately, execute the CV task
      generated when an assigned configlet is modified? (Default: :no)
    EOS

    defaultto false
  end

  newparam(:cvp_nodes) do
    desc <<-EOS
      A list of cvp cluster node hostnames or IP addresses
    EOS

    munge do |value|
      case value.class
      when String
        [value]
      else
        value
      end
    end

    validate do |value|
      case value.class
      when Array
        value.each do |item|
          unless item.is_a? String
            raise "value #{item.inspect} is invalid, must be Strings."
          end
        end
      when String
        unless item.is_a? String
          raise "value #{item.inspect} is invalid, must be Strings."
        end
      end
    end
  end

  newparam(:cvp_user) do
    desc <<-EOS
      CVP username
    EOS

    validate do |value|
      unless value.is_a? String
        raise "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newparam(:cvp_pass) do
    desc <<-EOS
      CVP password
    EOS

    validate do |value|
      unless value.is_a? String
        raise "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newparam(:timeout) do
    desc <<-EOS
      A CVP task will be considered fo have failed or be stuck if it takes
      longer than 'timeout' seconds. (Default: 900)
    EOS

    validate do |value|
      unless value.is_a? Integer
        raise "value #{value.inspect} is invalid, must be a Integer."
      end
    end

    defaultto 900
  end

  # Properties (state management)

  newproperty(:containers, :array_matching => :all) do
    desc <<-EOS
      List of container names in CVP to associate with the configlet.  May be
      the FQDN of a network element or the name of a container.
    EOS

    # Sort the arrays before comparing
    def insync?(current)
      current.sort == should.sort
    end

    validate do |value|
      unless value.is_a? String
        raise "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:content) do
    desc <<-EOS
      The EOS config that makes up the body of the configlet.
    EOS

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else raise "value #{value.inspect} is invalid, must be a String."
      end
    end
  end
end
