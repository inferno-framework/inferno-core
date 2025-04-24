Inferno::Application.register_provider(:suites) do
  prepare do
    target_container.start :logging

    require 'inferno/entities/test'
    require 'inferno/entities/test_group'
    require 'inferno/entities/test_suite'
    require 'inferno/entities/test_kit'
    require 'inferno/route_storage'

    files_to_load = Dir.glob(File.join(Dir.pwd, 'lib', '*.rb'))

    if ENV['APP_ENV'] == 'test'
      files_to_load.concat Dir.glob(File.join(Inferno::Application.root, 'spec', 'fixtures', '**', '*.rb'))
    end

    # Whenever the definition of a Runnable class ends, add it to the
    # appropriate repository.
    in_memory_entities_trace = TracePoint.trace(:end) do |trace|
      if trace.self < Inferno::Entities::Test ||
         trace.self < Inferno::Entities::TestGroup ||
         trace.self < Inferno::Entities::TestSuite ||
         trace.self < Inferno::Entities::TestKit
        trace.self.add_self_to_repository
      end
    end

    files_to_load.map! { |path| File.realpath(path) }

    files_to_load.each do |path|
      require_relative path
    end

    in_memory_entities_trace.disable

    Inferno::Entities::TestSuite.descendants.each do |descendant|
      # When ID not assigned in custom test suites, Runnable.id will return default ID
      # equal to the custom test suite's parent class name
      if descendant.id.blank? || descendant.id == 'Inferno::Entities::TestSuite'
        raise StandardError, "Error initializing test suite #{descendant.name}: test suite ID is not set"
      end
    end
  end
end
