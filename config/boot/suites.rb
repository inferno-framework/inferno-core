require_relative '../../lib/inferno/utils/suite_tracker'

Inferno::Application.boot(:suites) do
  init do
    use :logging, :entities

    files_to_load = Dir.glob(File.join(Inferno::Application.root, 'suites', '**', '*.rb'))

    if ENV['APP_ENV'] != 'production'
      files_to_load.concat Dir.glob(File.join(Inferno::Application.root, 'dev_suites', '**', '*.rb'))
    end

    if ENV['APP_ENV'] == 'test'
      files_to_load.concat Dir.glob(File.join(Inferno::Application.root, 'spec', 'fixtures', '**', '*.rb'))
    end

    previous_length = 0

    while files_to_load.length != previous_length
      previous_length = files_to_load.length
      files_to_load.reject! do |path|
        require_relative path
        Inferno::Utils::SuiteTracker.classes_defined_at_path[path].each(&:add_self_to_repository)
        true
      rescue Inferno::Exceptions::ParentNotLoadedException, NameError
        # Clear out the inline Test DSL classes, which will be added again on
        # the next pass.
        Inferno::Utils::SuiteTracker.classes_defined_at_path[path].delete_if { |klass| klass.name.nil? }
        false
      end
    end

    ObjectSpace.each_object(TracePoint, &:disable)

    unless files_to_load.empty?
      error_messages = files_to_load.each_with_object({}) do |path, errors|
        require_relative path
      rescue StandardError => e
        errors[path] = "#{e.message} -- #{e.backtrace_locations.first}"
      end

      error_message =
        error_messages
          .map { |path, message| "Unable to load #{path}: #{message}" }
          .join("\n")

      raise StandardError, error_message
    end
  end
end
