Inferno::Application.boot(:entities) do
  init do
    require_relative(File.join(Inferno::Application.root, 'inferno', 'exceptions'))

    require_relative(File.join(Inferno::Application.root, 'inferno', 'entities', 'attributes.rb'))
    require_relative(File.join(Inferno::Application.root, 'inferno', 'entities', 'entity.rb'))
    Dir.glob(File.join(Inferno::Application.root, 'inferno', 'entities', '*')).each do |path|
      require_relative path
    end
  end
end
