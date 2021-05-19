Inferno::Application.boot(:entities) do
  init do
    require_relative(File.join(Inferno::Application.root, 'lib', 'inferno', 'exceptions'))

    require_relative(File.join(Inferno::Application.root, 'lib', 'inferno', 'entities', 'attributes.rb'))
    require_relative(File.join(Inferno::Application.root, 'lib', 'inferno', 'entities', 'entity.rb'))
    Dir.glob(File.join(Inferno::Application.root, 'lib', 'inferno', 'entities', '*')).each do |path|
      require_relative path
    end
  end
end
