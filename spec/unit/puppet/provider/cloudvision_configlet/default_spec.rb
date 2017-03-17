require 'spec_helper'
require 'cvprac'
include FixtureHelpers

describe Puppet::Type.type('cloudvision_configlet').provider('default') do
  def load_default_settings
    @name = 'api_test_0'
    @content = "Interface Ethernet4\n   no shutdown\nend"
    @containers = ['dc01-rack3-torA.example.com']
    @ensure = :present
  end

  let(:provider) { subject }

  let(:properties) do
    load_default_settings
    {
      :name => @name,
      :content => @content,
      :containers => @containers,
      :ensure => @ensure,
      :provider => described_class.name
    }
  end
  # let(:resource) { subject.new(properties) }
  let(:resource) { Puppet::Type.type(:cloudvision_configlet).new(properties) }
  let(:provider) { resource.provider }

  # let(:CvpClient) { double('CvpClient') }
  # let(:CvpApi) { double('CvpApi') }
  # let(:cvp) { double('cvp') }
  let(:api) { double('api') }
  let(:configlets) { double('configlets') }
  let(:devices) { double('devices') }

  def configlets
    configlets = Fixtures[:configlets]
    return configlets if configlets
    JSON.parse(fixture('configlets'))
  end

  def devices
    devices = Fixtures[:devices]
    return devices if devices
    # fixture('devices')
    JSON.parse(fixture('devices'))
  end

  before :each do
    allow(described_class.api).to receive(:get_configlets).and_return(configlets)
    allow(provider.api).to receive(:get_configlets).and_return(configlets)
    allow(described_class.api).to receive(:get_devices_by_configlet_name).and_return(devices)
    allow(provider.api).to receive(:get_devices_by_configlet_name).and_return(devices)
    load_default_settings
  end

  it 'should return an array of instances' do
    # binding.pry
    # expect(subject.instances).to be_instance_of(Array)
    expect(described_class.instances).to be_instance_of(Array)
  end

  describe '.prefetch' do
    let :resources do
      {
        'api_test_0' => Puppet::Type.type(:cloudvision_configlet).new(name: @name),
        'api_test_99' => Puppet::Type.type(:cloudvision_configlet).new(name: 'api_test_99'),
      }
    end

    subject { described_class.prefetch(resources) }

    it 'resource providers are absent prior to calling .prefetch' do
      resources.values.each do |rsrc|
        expect(rsrc.provider.containers).to eq(:absent)
        expect(rsrc.provider.content).to eq(:absent)
      end
    end

    it 'sets the provider instance of the managed resource' do
      subject
      expect(resources['api_test_0'].provider.name).to eq(@name)
    end

    it 'does not set the provider instance of the unmanaged resource' do
      subject
      expect(resources['api_test_99'].provider.content).to eq(:absent)
    end

    it 'should prefetch resources' do
      # binding.pry
      # expect(subject.instances).to be_instance_of(Array)

      expect(described_class.instances).to be_instance_of(Array)
    end
  end

  context 'resource exists method' do
    describe '#exists?' do
      subject { provider.exists? }

      context 'when the resource does not exist on the system' do
        it { is_expected.to be_falsey }
      end

      context 'when the resource exists on the system' do
        let(:provider) do
          allow(described_class.api).to receive(:get_configlets).and_return(configlets)
          allow(described_class.api).to receive(:get_devices_by_configlet_name).and_return(devices)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end
  end

  context 'helper methods' do
    describe '#get_configlets' do
      it 'should return a hash' do
        expect(described_class.get_configlets).to be_instance_of(Hash)
      end
    end
  end

  describe 'setter property methods' do
    before:each do
      allow(provider.api).to receive(:add_configlet).and_return('configlet_1864961_16870926403631445')
      allow(provider).to receive(:add_configlet_to_element).and_return(nil)
    end

    describe '#create' do
      let(:tasks_by_device) do
        [{ 'workOrderEscalation' => nil,
           'workFlowDetailsId' => nil,
           'createdBy' => 'cvpadmin',
           'executedOnInLongFormat' => 0,
           'executedBy' => nil,
           'workOrderDetails' =>
     { 'workOrderDetailsId' => nil,
       'netElementHostName' => 'veos-l-11.aristanetworks.com',
       'netElementId' => '00:50:56:60:2c:a8',
       'ipAddress' => '192.0.2.200',
       'workOrderId' => nil,
       'factoryId' => 1,
       'serialNumber' => '',
       'id' => 13 },
           'createdOnInLongFormat' => 1_488_799_943_226,
           'workOrderState' => 'ACTIVE',
           'workOrderId' => '18',
           'templateId' => 'ztp',
           'currentTaskType' => 'User Task',
           'currentTaskName' => 'Execute',
           'workOrderUserDefinedStatus' => 'Pending',
           'taskStatus' => 'ACTIVE',
           'factoryId' => 1,
           'data' =>
     { 'currentparentContainerId' => 'container_76_24208204830466',
       'WORKFLOW_ACTION' => 'Configlet Push',
       'VIEW' => 'CONFIG',
       'newparentContainerId' => 'container_76_24208204830466',
       'NETELEMENT_ID' => '00:50:56:60:2c:a8',
       'ignoreConfigletList' => [],
       'IS_CONFIG_PUSH_NEEDED' => 'yes' },
           'description' => 'Configlet Assign: to Device 00:50:56:60:2c:a8',
           'note' => nil,
           'name' => nil,
           'id' => 7 }]
      end
      let(:content) { "Interface Ethernet4\n   shutdown\nend" }
      it 'sets ensure on the resource' do
        # allow(provider.api).to receive(:get_pending_tasks_by_device).and_return(tasks_by_device)
        # allow(described_class).to receive(:add_configlet_to_element).and_return(nil)
        # allow(described_class).to receive(:handle_tasks).and_return(nil)
        # allow(provider).to receive(:get_device_by_name).and_return({})
        # binding.pry
        expect(provider.api).to receive(:add_configlet)
        expect(provider).to receive(:add_configlet_to_element)
        provider.create
        # provider.content = "Interface Ethernet4\n   shutdown\nend"
        # provider.containers = ['dev1']
        # provider.flush
        expect(provider.ensure).to eq(:present)
        expect(provider.content).to eq(@content)
      end
    end

    describe '#containers=(value)' do
      it 'sets containers on the resource' do
        allow(provider).to receive(:remove_configlet_from_element).and_return(nil)
        allow(provider).to receive(:add_configlet_to_element).and_return(nil)

        provider.create
        provider.containers = %w(one three)
        # provider.flush
        expect(provider.containers).to eq(%w(one three))
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        # resource[:ensure] = :absent
        # expect(api).to receive(:delete)
        # provider.destroy
        # provider.flush
        # expect(provider.ensure).to eq(:absent)
      end
    end

    describe '#content' do
    end

    describe '#content' do
    end
  end

  describe 'getter property methods' do
  end
end
