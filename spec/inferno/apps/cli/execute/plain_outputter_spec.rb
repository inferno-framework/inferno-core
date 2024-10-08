require_relative '../../../../../lib/inferno/apps/cli/execute/plain_outputter'
require_relative 'outputter_spec'

RSpec.describe Inferno::CLI::Execute::PlainOutputter do # rubocop:disable RSpec/FilePath

  let(:instance) { described_class.new }
  let(:results) { create_list(:result, 2) }
  let(:options) { { outputter: 'plain', verbose: true } }

  include_examples 'outputter_spec', described_class

  it 'never outputs a color code' do
    expect do
      instance.print_start_message(options)
      instance.print_around_run(options) { ' ' }
      instance.print_results(options, results)
      instance.print_end_message(options)
      #instance.print_error(options, StandardError.new('Mock Error'))
    end.not_to output(/\033/).to_stdout    
  end

end
