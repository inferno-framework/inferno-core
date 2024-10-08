require_relative '../../../../../lib/inferno/apps/cli/execute/quiet_outputter'
require_relative 'outputter_spec'

RSpec.describe Inferno::CLI::Execute::QuietOutputter do # rubocop:disable RSpec/FilePath

  let(:instance) { described_class.new }
  let(:results) { create_list(:result, 2) }

  include_examples 'outputter_spec', described_class

  it 'never outputs when verbose is false' do
    options = { outputter: 'quiet', verbose: false }

    expect do
      instance.print_start_message(options)
      instance.print_around_run(options) { ' ' }
      instance.print_results(options, results)
      instance.print_end_message(options)
      instance.print_error(options, StandardError.new('Mock Error'))
    end.not_to output(/./).to_stdout    
  end

  it 'outputs error when verbose is true' do
    options = { outputter: 'quiet', verbose: true }
    expect { instance.print_error(options, StandardError.new('Mock Error')) }.to output.to_stdout
  end

end
