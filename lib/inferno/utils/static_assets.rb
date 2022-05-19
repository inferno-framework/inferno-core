module Inferno
  module Utils
    # @private
    class StaticAssets
      class << self
        def static_assets_folder
          @static_assets_folder ||=
            File.expand_path(File.join(inferno_path, 'public'))
        end

        def base_path
          @base_path ||= Application['base_path']
        end

        def public_path
          @public_path ||= "/#{base_path}/public".gsub('//', '/')
        end

        def inferno_path
          @inferno_path ||= File.expand_path(File.join(__dir__, '..'))
        end

        # A hash of urls => file_paths which will be served with `Rack::Static`
        def static_assets_map
          puts '-------'
          puts static_assets_folder
          Dir.glob(File.join(static_assets_folder, '*'))
            .each_with_object({}) do |filename, hash|
              puts "#{public_path}/#{File.basename(filename)} : #{filename}"
              hash["#{public_path}/#{File.basename(filename)}"] = filename.delete_prefix(inferno_path)
            end
        end
      end
    end
  end
end
