require_relative 'runnable_context'

RSpec.configure do |config|
  config.define_derived_metadata do |metadata|
    if metadata[:described_class].present? && metadata[:described_class].is_a?(Inferno::DSL::Runnable)
      metadata[:runnable] = true
    end
  end

  config.include_context 'when testing a runnable', runnable: true
end
