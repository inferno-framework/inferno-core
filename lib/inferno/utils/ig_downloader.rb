module Inferno
  module Utils
    module IgDownloader
      FHIR_PACKAGE_NAME_REG_EX = /^[a-z][a-zA-Z0-9-]*\.([a-z][a-zA-Z0-9-]*\.?)*/
      HTTP_URI_REG_EX = %r{^https?://[^/?#]+[^?#]*}
      FILE_URI_REG_EX = %r{^file://(.+)}
      HTTP_URI_END_REG_EX = %r{[^/]*\.x?html?$}

      def ig_path
        File.join('lib', library_name, 'igs')
      end

      def ig_file(suffix = nil)
        File.join(ig_path, suffix ? "package_#{suffix}.tgz" : 'package.tgz')
      end

      def load_ig(ig_input, idx = nil, thor_config = { verbose: true }, output_path = nil)
        case ig_input
        when FHIR_PACKAGE_NAME_REG_EX
          uri = ig_registry_url(ig_input)
        when HTTP_URI_REG_EX
          uri = ig_http_url(ig_input)
        when FILE_URI_REG_EX
          uri = ig_input[7..]
        else
          raise StandardError, <<~FAILED_TO_LOAD
            Could not find implementation guide: #{ig_input}
          FAILED_TO_LOAD
        end

        destination = output_path || ig_file(idx)
        # use Thor's get to support CLI options config
        get(uri, destination, thor_config)
        uri
      end

      def ig_registry_url(ig_npm_style)
        unless ig_npm_style.include? '@'
          raise StandardError, <<~NO_VERSION
            No IG version specified for #{ig_npm_style}; you must specify one with '@'. I.e: hl7.fhir.us.core@6.1.0
          NO_VERSION
        end

        package_name, version = ig_npm_style.split('@')
        "https://packages.fhir.org/#{package_name}/-/#{package_name}-#{version}.tgz"
      end

      def ig_http_url(ig_page_url)
        return ig_page_url if ig_page_url.end_with? 'package.tgz'

        return "#{ig_page_url}package.tgz" if ig_page_url.end_with? '/'

        ig_page_url.gsub(HTTP_URI_END_REG_EX, 'package.tgz')
      end
    end
  end
end
