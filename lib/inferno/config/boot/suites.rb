Inferno::Application.boot(:suites) do
  init do
    use :logging

    require 'inferno/entities/test'
    require 'inferno/entities/test_group'
    require 'inferno/entities/test_suite'

    files_to_load = Dir.glob(File.join(Dir.pwd, 'lib', '*.rb'))

    if ENV['LOAD_DEV_SUITES'].present?
      ENV['LOAD_DEV_SUITES'].split(',').map(&:strip).reject(&:empty?).each do |suite|
        files_to_load.concat Dir.glob(File.join(Inferno::Application.root, 'dev_suites', suite, '**', '*.rb'))
      end
    end

    if ENV['APP_ENV'] == 'test'
      files_to_load.concat Dir.glob(File.join(Inferno::Application.root, 'spec', 'fixtures', '**', '*.rb'))
    end

    files_to_load.map! { |path| File.realpath(path) }

    files_to_load.each do |path|
      require_relative path
    end

    ObjectSpace.each_object(TracePoint, &:disable)
  end
end
