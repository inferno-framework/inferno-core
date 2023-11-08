require 'dry/inflector'

module Inferno
  module CLI
    class New

      @@inflector = Dry::Inflector.new do |inflections|
        # TODO add custom inflections here... if we want to
        # inflections.acronym 'FHIR', 'HTTP'
      end

      def run(name, implementation_guide = nil)
        @name = name

        puts "This will generate a new inferno test kit called #{name} with #{implementation_guide || 'no'} IG"
        puts ''
        puts 'Names:'
        {'folder': folder_name, 'lib': lib_name, 'file': file_name, 'module': module_name}.each do |k, v|
          puts "#{k}: #{v}"
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

    end
  end
end
