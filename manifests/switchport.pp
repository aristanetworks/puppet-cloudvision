# Class: cloudvision::switchport
# ===========================
#
# Full description of class switchport here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'cloudvision::switchport':
#      host => 'server3-25',
#      rack => 'dc1-rack3',
#      port => '2/14',
#      template =>  'dc1-esx-host',
#    }
#
# Authors
# -------
#
# Arista EOS+ CS <eosplus-dev@arista.com>
# Jere Julian <jere@arista.com>
#
# Copyright
# ---------
#
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
#
define cloudvision::switchport (
  String $rack,
  String $port,
  String $template,
){

  #portnum = $port.scanf('%i') |$pval| {}
  #            unless $pval[0] =~ Integer {
  #              fail "Invalid network port: ${pval[0]}"
  #            }
  #            #unless $x[0] > 0 && $x[0] <= 20 {
  #            #  fail "Only ports 1-20 may be used. Requested: $x[0]"
  #            #}
  #            $pval[0]
  #          }
  $portnum = $port.scanf('%i')[0]
  # Check if portnum is within a valid range

  $host = $title

  $tor = "dc1-rack${rack}-tor"
  $configlet = "${tor}-port-${portnum}"
  cloudvision_configlet { $configlet:
    content => template($template),
    # template "profile/esx_host.erb" loads
    # file: $environment/modules/profile/templates/esx_host.erb
  }

}
