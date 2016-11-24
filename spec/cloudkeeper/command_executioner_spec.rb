require 'spec_helper'

describe Cloudkeeper::CommandExecutioner do
  subject(:command_executioner) { described_class }

  describe '#execute' do
    let(:command) { instance_double(Mixlib::ShellOut) }

    before do
      expect(Mixlib::ShellOut).to receive(:new).with('arg1', 'arg2', 'arg3') { command }
      expect(command).to receive(:run_command)
      allow(command).to receive(:error?) { false }
      allow(command).to receive(:stdout) { 'output' }
      allow(command).to receive(:stderr) { 'error' }
      allow(command).to receive(:command) { 'command' }
    end

    context 'normal run' do
      it 'executes external command and returns standard output' do
        expect(command_executioner.execute('arg1', 'arg2', 'arg3')).to eq('output')
      end
    end

    context 'with error' do
      before do
        allow(command).to receive(:error?) { true }
      end

      it 'executes command and raises CommandExecutionError exception' do
        expect { command_executioner.execute('arg1', 'arg2', 'arg3') }.to raise_error(Cloudkeeper::Errors::CommandExecutionError)
      end
    end
  end
end
