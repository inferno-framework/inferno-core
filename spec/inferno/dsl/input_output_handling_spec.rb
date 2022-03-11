RSpec.describe Inferno::DSL::InputOutputHandling do
  describe '.available_inputs' do
    it 'does not combine differently named child inputs' do
      group = Class.new(Inferno::Entities::TestGroup) do
        id SecureRandom.uuid
        group do
          config(inputs: { a: { name: :b } })
          test do
            input :a
          end
        end

        group do
          config(inputs: { a: { name: :c } })
          test do
            input :a
          end
        end
      end

      expect(group.available_inputs.length).to eq(2)
    end
  end
end

