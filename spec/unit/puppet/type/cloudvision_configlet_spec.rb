require 'spec_helper'

# find all parameters that don't have default values and put in here
# ensure validation occurs
describe Puppet::Type.type('cloudvision_configlet') do
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:type) { described_class.new(name: 'Configlet', catalog: catalog) }

  # these should be only the require parameters
  let(:required_properties) do
    {
      :name => 'rack3-tor-Ethernet4',
      :content => "Interface Ethernet4\n   no shutdown\nend",
      :containers => ['dc01-rack3-torA.example.com']
    }
  end

  let(:optional_properties) do
    {
      :auto_run => true
    }
  end

  let(:properties) do
    required_properties.merge(optional_properties)
  end

  let(:name) do
    'rack3-tor-Ethernet4'
  end

  let(:type_instance) do
    Puppet::Type.type('cloudvision_configlet').new(:name => name)
  end

  # .that_requires('Package[cvprac]')

  it_behaves_like 'an ensurable type', name: 'Configlet'

  describe 'name' do
    include_examples 'name is the namevar'
  end

  describe 'auto_run' do
    let(:attribute) { :auto_run }
    subject { described_class.attrclass(attribute) }

    include_examples 'parameter'
    include_examples '#doc Documentation'
    include_examples 'boolean parameter'
  end

  describe 'containers' do
    let(:attribute) { :containers }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'array of strings value'
  end

  describe 'content' do
    let(:attribute) { :content }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'string value'
  end
end
