module Inferno
  module Config
    module Boot
      # Extracted from the :suites provider below so the enable_when
      # validation can be unit tested against plain Test/TestGroup/TestSuite
      # classes, instead of requiring a full application boot (which only
      # happens once per process) just to exercise the raise.
      module Suites
        module_function

        # A circular or undefined enable_when dependency means the input
        # involved can never be enabled, so this is treated as fatal at load
        # time rather than left for developers to discover once the suite is
        # already running. `enable_when` is uninheritable, so a problem local
        # to a group or test can be hidden from the suite's own merged view if
        # a parent re-declares the same input name without repeating
        # `enable_when` -- checking every runnable in the tree, not just the
        # suite, is what catches that case.
        def check_enable_when_errors!(descendant)
          [*descendant.all_descendants.reverse, descendant].each do |runnable|
            enable_when_errors = runnable.enable_when_cycle_messages
            next if enable_when_errors.empty?

            raise StandardError,
                  "Error initializing test suite #{descendant.name} (id: #{descendant.id}), " \
                  "in '#{runnable.title || runnable.id}' (id: #{runnable.id}): #{enable_when_errors.join}"
          end
        end
      end
    end
  end
end

Inferno::Application.register_provider(:suites) do
  prepare do
    target_container.start :logging

    require 'inferno/entities/test'
    require 'inferno/entities/test_group'
    require 'inferno/entities/test_suite'
    require 'inferno/entities/test_kit'
    require 'inferno/route_storage'

    files_to_load = Dir.glob(File.join(Dir.pwd, 'lib', '*.rb'))

    if ENV['LOAD_DEV_SUITES'].present?
      ENV['LOAD_DEV_SUITES'].split(',').map(&:strip).reject(&:empty?).each do |suite|
        files_to_load.concat Dir.glob(File.join(Inferno::Application.root, 'dev_suites', suite, '**', '*.rb'))
      end
    end

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

      Inferno::Config::Boot::Suites.check_enable_when_errors!(descendant)

      # This will lock the short IDs if a short ID map for this suite is present
      descendant.assign_short_ids
    end
  end
end
