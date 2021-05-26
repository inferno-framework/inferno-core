Inferno::Application.boot(:suites) do
  init do
    use :logging

    files_to_load = Dir.glob(File.join(Inferno::Application.root, 'suites', '**', '*.rb'))

    if ENV['APP_ENV'] != 'production'
      files_to_load.concat Dir.glob(File.join(Inferno::Application.root, 'dev_suites', '**', '*.rb'))
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
