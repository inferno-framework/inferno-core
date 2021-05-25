Inferno::Application.boot(:logging) do
  init do
    logger =
      if Inferno::Application.env == :test
        log_file_directory = File.join(Inferno::Application.root, 'tmp')
        FileUtils.mkdir_p(log_file_directory)
        log_file_path = File.join(log_file_directory, 'test.log')
        log_file = File.open(log_file_path, File::WRONLY | File::APPEND | File::CREAT)
        Logger.new(log_file)
      else
        Logger.new($stdout)
      end

    register('logger', logger)
  end
end
