require 'spec_helper'

# find all parameters that don't have default values and put in here
# ensure validation occurs
describe Puppet::Type.type('cloudvision_configlet') do
  # these should be only the require parameters
  let(:required_properties) do
    {

      :name => 'some_name'
    }
  end

  let(:optional_properties) do
    {

    }
  end

  let(:properties) do
    required_properties.merge(optional_properties)
  end

  let(:name) do
    'some_name'
  end

  let(:type_instance) do
    #
    Puppet::Type.type('cloudvision_configlet').new(:name => name)
  end
end
