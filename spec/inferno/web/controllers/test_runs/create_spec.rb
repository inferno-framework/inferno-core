RSpec.describe Inferno::Web::Controllers::TestRuns::Create do
  let(:create) do
    described_class.new
  end

  let(:test_group) do
    example_test_group = Class.new(Inferno::Entities::TestGroup)
    example_test_group.input :foo
    example_test_group.run_as_group
    example_test_group.group(:not_runnable_group)
    example_test_group
  end

  let(:runnable_test_group) do
    test_group
  end

  describe '#verify_runnable' do
    it 'is a no-op when required inputs are provided and is runnable' do
      expect do
        create.verify_runnable(test_group, [
                                 { name: 'foo', value: 'foo', type: 'text' }
                               ])
      end.to_not(
        raise_error
      )
    end

    it 'raises a RequiredInputsNotFound Exception when the runnable is missing required inputs' do
      expect do
        create.verify_runnable(test_group, [
                                 { name: 'bar', value: 'bar', type: 'text' }
                               ])
      end.to(
        raise_error(Inferno::Exceptions::RequiredInputsNotFound, 'Missing the following required inputs: foo')
      )
    end

    it 'raises a NotUserRunnableException when the runnable is not user runnable and is provided all required inputs' do
      expect do
        create.verify_runnable(test_group.groups.first, [
                                 { name: 'foo', value: 'foo', type: 'text' }
                               ])
      end.to(
        raise_error(Inferno::Exceptions::NotUserRunnableException)
      )
    end
  end
end
