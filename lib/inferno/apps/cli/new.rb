require 'dry/inflector'
require 'faraday'
require 'zip'

module Inferno
  module CLI
    class New

      @@inflector = Dry::Inflector.new do |inflections|
        inflections.acronym 'FHIR'
      end

      GITHUB_TEMPLATE_URL = 'https://codeload.github.com/inferno-framework/inferno-template/legacy.zip/refs/heads/main'

      def run(name, implementation_guide = nil)
        @name = name

        github_template_response = Faraday.get(GITHUB_TEMPLATE_URL)
        raise StandardError.new('Failed to download inferno-framework/inferno-template from GitHub.') unless github_template_response.status == 200

        mkdir_p folder_name
        extract_zip(github_template_response.body) do |name_to_sub, path, contents|
          # preform all template substitutions
          path.gsub! name_to_sub, folder_name
          path.gsub! 'inferno-template', folder_name
          path.gsub! 'inferno_template', lib_name

          contents.gsub! 'InfernoTemplate', module_name
          contents.gsub! 'inferno_template', lib_name
          contents.gsub! 'Inferno Template', human_name
          contents.gsub! 'Inferno Test Kit Template', human_name
          contents.gsub! 'Inferno Team', 'TODO'
          contents.gsub! 'inferno@groups.mitre.org', 'TODO@example.com'            

          unless File.exists?(path)
            FileUtils.mkdir_p(File.dirname(path))
            File.create(path) do |f|
              f.write(contents)
            end
            puts "created #{path}"
          end
        end
      end

      private
        # root folder name, i.e: inferno-template
        def folder_name
          @@inflector.dasherize(@name)
        end

        # lib folder name, i.e: inferno_template
        def lib_name
          @@inflector.underscore(@name)
        end

        # file name with suffix extension, i.e: inferno_template.rb
        def file_name(suffix = '.rb')
          @@inflector.underscore(@name) + suffix
        end

        # module name, i.e: InfernoTemplate
        def module_name
          @@inflector.camelize(@name)
        end

        # English grammatical name, i.e: Inferno template
        def human_name
          @@inflector.humanize(@name)
        end

        def extract_zip(zip_binary, &block)
          # requires block:
          # yields: name to sub, file path, file contents

          zip_stream = Zip::InputStream.new(StringIO.new(zip_binary))
          original_name = zip_stream.get_next_entry.name

          while zip_entry = zip_stream.get_next_entry
            # unless File.exist?(zip_entry.name)
            #   FileUtils::mkdir_p(File.dirname(zip_entry.name))
            #   zip_stream.extract(zip_entry, zip_entry.name) 
            # end
            yield(original_name, zip_entry.name, zip_entry.get_input_stream.read)
          end
        end

    end
  end
end
