require 'spec_helper'
require 'shared_contexts'

describe 'cloudvision::switchport' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'server-name' }

  # Set Hiera data
  let(:hiera_data) do
    {}
  end

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:facts) do
    {}
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      :rack => 'A2',
      :port => '23',
      :template => 'cloudvision/single_attached_vlan.erb',
      #:auto_run => true,
      :variables => { 'vlan' => 123 },
      :host_port_range => {
        'min' => 4,
        'max' => 60
      },
      :rack_switch_map => {
        'A2' => 'dc01-a2-tor.example.com'
      }
    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)

  let(:content) do
    # squiggly heredoc isn't supported till Ruby 2.3, Puppet 5?
    <<-HEREDOC
interface Ethernet23
   description Host server-name managed by puppet template cloudvision/single_attached_vlan.erb
   switchport mode access
   switchport access vlan 123
   no shutdown
!
end
    HEREDOC
  end

  it do
    is_expected.to contain_cloudvision_configlet('dc01-a2-tor.example.com-port-23')
      .with({
          'content' => content,
          'containers' => ['dc01-a2-tor.example.com'],
          'auto_run' => false,
          })
  end
end
