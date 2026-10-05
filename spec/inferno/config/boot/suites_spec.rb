require 'spec_helper'

RSpec.describe Inferno::Config::Boot::Suites do
  describe '.check_enable_when_errors!' do
    it 'does not raise when there are no enable_when errors' do
      suite = Class.new(Inferno::Entities::TestSuite) { id SecureRandom.uuid }

      expect { described_class.check_enable_when_errors!(suite) }.to_not raise_error
    end

    it 'raises when a runnable in the tree has a circular enable_when dependency' do
      suite = Class.new(Inferno::Entities::TestSuite) do
        id SecureRandom.uuid

        test do
          id 't'
          input :a, optional: true, enable_when: { input_name: 'b', value: 'x' }
          input :b, optional: true, enable_when: { input_name: 'a', value: 'y' }
          run { pass }
        end
      end

      expect { described_class.check_enable_when_errors!(suite) }
        .to raise_error(StandardError, /Circular enable_when dependency detected in input 'a'/)
    end

    it 'raises when a runnable in the tree has an enable_when referencing an undefined input' do
      suite = Class.new(Inferno::Entities::TestSuite) do
        id SecureRandom.uuid

        test do
          id 't'
          input :a, optional: true, enable_when: { input_name: 'b', value: 'x' }
          run { pass }
        end
      end

      expect { described_class.check_enable_when_errors!(suite) }
        .to raise_error(StandardError, %r{references 'b', which is not an input defined on the same test/group/suite})
    end
  end
end
