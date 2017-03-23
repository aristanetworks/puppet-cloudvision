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

##
# PuppetX namespace
module PuppetX
  ##
  # Cloudvision namespace
  module Cloudvision
    ##
    # RacProviderMixin module
    module RacProviderMixin
      def prefetch(resources)
        instances.each do |prov|
          if resource = resources[prov.name]
            resource.provider = prov
          end
        end
      end

      ##
      # Instance of Cvprac::CvpApi used to sending and receiving
      # messages to CloudVision instances.
      #
      # @return [CvpApi] An instance of Cvprac::CvpApi
      def api
        return @api if @api
        cvp = CvpClient.new
        cvp.connect(cvp_config['nodes'],
                    cvp_config['username'],
                    cvp_config['password'])
        @api = CvpApi.new(cvp)
      end

      ##
      # Load a cloudvision.yaml, to get the CVP nodes and credentials to use.
      #
      # @param [Hash] opts The set of options configured on the resource
      # @option opts [String] :filename Full path to a YAML config file
      #
      # @return [Hash] Ex: {"nodes"=>["192.0.2.101", "192.0.2.102",
      #   "192.0.2.102"] "username"=>"cvpadmin", "password"=>"arista123"}
      def load_config(**opts)
        search_path = ['/mnt/flash/cloudvision.yaml']
        # Add the home directory path if the HOME environement var is defined.
        search_path.insert(0, '~/.cloudvision.yaml') if ENV.key?('HOME')
        search_path.insert(0, '.cloudvision.yaml') if ENV.key?('HOME')
        search_path.insert(0, ENV['CLOUDVISION_CONF']) if ENV.key?('CLOUDVISION_CONF')

        path = opts[:filename] || search_path

        path.each do |fn|
          fn = File.expand_path(fn)
          return YAML.load_file(fn) if File.exist?(fn)
        end

        raise 'No cloudvision.yaml config found in search path.'
      end
      private :load_config

      ##
      # Lazily load the cloudvision.yaml
      #
      # @param [Hash] opts The set of options configured on the resource
      # @option opts [String] :filename Full path to a YAML config file
      #
      # @return [Hash] Ex: {"nodes"=>["192.0.2.101", "192.0.2.102",
      #   "192.0.2.102"] "username"=>"cvpadmin", "password"=>"arista123"}
      def cvp_config(**opts)
        @config ||= load_config(opts)
      end
      private :cvp_config
    end
  end
end
