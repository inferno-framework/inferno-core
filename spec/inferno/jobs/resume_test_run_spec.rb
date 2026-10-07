RSpec.describe Inferno::Jobs::ResumeTestRun do
  it 'does not retry, since a retry would rerun the test that was in progress' do
    expect(described_class.get_sidekiq_options['retry']).to be(false)
  end
end
