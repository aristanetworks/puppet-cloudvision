require 'spec_helper'
describe 'cloudvision' do
  context 'with default values for all parameters' do
    it { should contain_class('cloudvision') }
  end
end
