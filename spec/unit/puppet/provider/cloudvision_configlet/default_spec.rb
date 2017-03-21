require 'spec_helper'
require 'cvprac'
include FixtureHelpers

describe Puppet::Type.type('cloudvision_configlet').provider('default') do
  def load_default_settings
    @name = 'api_test_0'
    @auto_run = false
    @content = "Interface Ethernet4\n   no shutdown\nend"
    @containers = ['dc01-rack3-torA.example.com']
    @ensure = :present
  end

  let(:provider) { subject }

  let(:properties) do
    load_default_settings
    {
      :name => @name,
      :auto_run => @auto_run,
      :content => @content,
      :containers => @containers,
      :ensure => @ensure,
      :provider => described_class.name
    }
  end
  let(:resource) { Puppet::Type.type(:cloudvision_configlet).new(properties) }
  let(:provider) { resource.provider }

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
    allow(described_class.api).to receive(:get_configlets)
      .and_return(configlets)
    allow(provider.api).to receive(:get_configlets).and_return(configlets)
    allow(described_class.api).to receive(:get_devices_by_configlet_name)
      .and_return(devices)
    allow(provider.api).to receive(:get_devices_by_configlet_name)
      .and_return(devices)
    load_default_settings
  end

  it 'should return an array of instances' do
    expect(described_class.instances).to be_instance_of(Array)
  end

  describe '.prefetch' do
    let :resources do
      {
        'api_test_0' => Puppet::Type.type(:cloudvision_configlet)
          .new(name: @name),
        'api_test_99' => Puppet::Type.type(:cloudvision_configlet)
          .new(name: 'api_test_99'),
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
          allow(described_class.api).to receive(:get_configlets)
            .and_return(configlets)
          allow(described_class.api).to receive(:get_devices_by_configlet_name)
            .and_return(devices)
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

    describe '#handle_tasks(task_ids)' do
      it 'executes tasks and waits for completion' do
        allow(provider.api).to receive(:execute_task)
          .and_return({ 'data' => 'success' })
        allow(provider.api).to receive(:get_task_by_id)
          .and_return({ 'taskStatus' => 'STARTED' },
                      { 'taskStatus' => 'INPROGRESS' },
                      { 'taskStatus' => 'COMPLETED' })

        expect(provider.api).to receive(:execute_task).with('12')
        expect(provider.api).to receive(:get_task_by_id).exactly(3).times
        provider.handle_tasks('12')
      end
    end

    describe '#add_configlet_to_element(device, auto_run)' do
      before :each do
        allow(provider.api).to receive(:get_device_by_name)
          .and_return({ 'taskIdList' => ['task_1'] })
        allow(provider.api).to receive(:get_configlet_by_name)
          .and_return(configlets['data'][0])
        allow(provider.api).to receive(:apply_configlets_to_device)
          .and_return({ 'data' => { 'taskIds' => ['task_1', 'task_2'] } })
        allow(provider).to receive(:handle_tasks).and_return(nil)
      end

      it 'with defaults (auto_run=false), calls cvprac APIs and returns' do
        expect(provider.api).to receive(:apply_configlets_to_device)
        expect(provider).not_to receive(:handle_tasks)
        provider.add_configlet_to_element('some_dev')
      end

      it 'with auto_run=true, calls cvprac APIs and handle_tasks' do
        expect(provider.api).to receive(:apply_configlets_to_device)
        expect(provider).to receive(:handle_tasks).with(['task_1', 'task_2'])
        provider.add_configlet_to_element('some_dev', true)
      end
    end

    describe '#remove_configlet_from_element(device, auto_run)' do
      before :each do
        allow(provider.api).to receive(:get_device_by_name)
          .and_return({ 'taskIdList' => ['task_1'] })
        allow(provider.api).to receive(:get_configlet_by_name)
          .and_return(configlets['data'][0])
        allow(provider.api).to receive(:remove_configlets_from_device)
          .and_return({ 'data' => { 'taskIds' => ['task_1', 'task_2'] } })
        allow(provider).to receive(:handle_tasks).and_return(nil)
      end

      it 'with defaults (auto_run=false), calls cvprac APIs and returns' do
        expect(provider.api).to receive(:remove_configlets_from_device)
        expect(provider).not_to receive(:handle_tasks)
        provider.remove_configlet_from_element('some_dev')
      end

      it 'with auto_run=true, calls cvprac APIs and handle_tasks' do
        expect(provider.api).to receive(:remove_configlets_from_device)
        expect(provider).to receive(:handle_tasks).with(['task_1', 'task_2'])
        provider.remove_configlet_from_element('some_dev', true)
      end
    end
  end

  describe 'setter property methods' do
    before:each do
      allow(provider.api).to receive(:add_configlet)
        .and_return('configlet_1864961_16870926403631445')
      allow(provider).to receive(:add_configlet_to_element).and_return(nil)
    end

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

    describe '#create' do
      let(:content) { "Interface Ethernet4\n   shutdown\nend" }
      it 'sets ensure on the resource' do
        expect(provider.api).to receive(:add_configlet)
        expect(provider).to receive(:add_configlet_to_element)
        provider.create
        expect(provider.ensure).to eq(:present)
        expect(provider.content).to eq(@content)
      end
    end

    describe '#containers=(value)' do
      it 'sets containers on the resource' do
        allow(provider).to receive(:remove_configlet_from_element)
          .and_return(nil)
        allow(provider).to receive(:add_configlet_to_element).and_return(nil)

        provider.create
        provider.containers = %w(node-1 node-3)
        expect(provider.containers).to eq(%w(node-1 node-3))
      end
    end

    describe '#content=(value)' do
      let(:content) { "Interface Ethernet4\n   shutdown\nend" }
      it 'with auto_run=false, sets content on the resource' do
        allow(provider.api).to receive(:get_pending_tasks_by_device)
          .and_return(tasks_by_device)
        allow(provider.api).to receive(:get_configlet_by_name)
          .and_return(configlets['data'][0])
        allow(provider).to receive(:handle_tasks).and_return(nil)

        resource[:auto_run] = false
        expect(provider.api).to receive(:get_configlet_by_name)
        expect(provider.api).to receive(:update_configlet)
        expect(provider).not_to receive(:handle_tasks)
        provider.create
        provider.content = content
        expect(provider.ensure).to eq(:present)
        expect(provider.content).to eq(content)
      end

      it 'with auto_run=true, sets content on the resource' do
        allow(provider.api).to receive(:get_pending_tasks_by_device)
          .and_return(tasks_by_device)
        allow(provider.api).to receive(:get_configlet_by_name)
          .and_return(configlets['data'][0])
        allow(provider).to receive(:handle_tasks).and_return(nil)

        resource[:auto_run] = true
        expect(provider.api).to receive(:get_configlet_by_name)
        expect(provider.api).to receive(:update_configlet)
        expect(provider).to receive(:handle_tasks)
        provider.create
        provider.content = content
        expect(provider.ensure).to eq(:present)
        expect(provider.content).to eq(content)
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        allow(provider.api).to receive(:get_configlet_by_name)
          .and_return(configlets['data'][0])
        allow(provider.api).to receive(:delete_configlet)
          .and_return('success')

        resource[:ensure] = :absent
        expect(provider.api).to receive(:get_configlet_by_name)
        expect(provider.api).to receive(:delete_configlet)
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end

      let(:configlet) do
        { 'isDefault' => 'no',
          'containerCount' => 2,
          'netElementCount' => 1,
          'isAutoBuilder' => 'false',
          'reconciled' => false,
          'dateTimeInLongFormat' => 1_469_067_229_602,
          'factoryId' => 1,
          'config' =>
          "!username admin privilege 15 role network-admin secret 0 admin\n"\
              "!username cvpadmin privilege 15 role network-admin secret 0 "\
              "arista123\nusername admin privilege 15 role network-admin "\
              "secret 5 $1$7IJPvFto$.3IzcPDr5MJiBID8iCEFb1 \n"\
              "username cvpadmin privilege 15 role network-admin secret 5 "\
              "$1$e8zc.bhO$G1YLdeQGXLBS1J8T.oeJT/ \n! \n"\
              "management api http-commands\nno shutdown\n",
          'user' => 'cvpadmin',
          'note' => nil,
          'name' => 'cvp_base',
          'key' => 'configlet_17_22451036385055',
          'id' => 3,
          'type' => 'Static' }
      end

      let(:devices) do
        { 'total' => 1,
          'data' =>
          [{ 'ipAddress' => '192.0.2.200',
             'appliedBy' => 'cvpadmin',
             'containerName' => 'Spines',
             'totalDevicesCount' => 0,
             'appliedDate' => 1_469_068_986_862,
             'hostName' => 'veos-l-11.aristanetworks.com' }] }
      end

      it 'removes configlet references on nodes' do
        allow(provider.api).to receive(:get_configlet_by_name)
          .and_return(configlet)
        allow(provider.api).to receive(:get_devices_by_configlet_name)
          .and_return(devices)
        allow(provider).to receive(:remove_configlet_from_element)
        allow(provider.api).to receive(:delete_configlet).and_return('success')

        resource[:ensure] = :absent
        expect(provider.api).to receive(:get_configlet_by_name)
        expect(provider).to receive(:remove_configlet_from_element)
        expect(provider.api).to receive(:delete_configlet)
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end
    end
  end

  describe 'getter property methods' do
  end
end
