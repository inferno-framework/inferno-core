require_relative '../../../../lib/inferno/apps/cli/execute/json_outputter'
require_relative 'outputter_spec'

RSpec.describe Inferno::CLI::Execute::JSONOutputter do
  include_examples 'outputter_spec', described_class
end
