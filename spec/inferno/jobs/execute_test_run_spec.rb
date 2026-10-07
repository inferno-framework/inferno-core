RSpec.describe Inferno::Jobs::ExecuteTestRun do
  it 'does not retry, since a retry would replay the whole test run' do
    expect(described_class.get_sidekiq_options['retry']).to be(false)
  end
end
