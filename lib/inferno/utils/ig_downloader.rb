module Inferno
  module Utils
    module IgDownloader
      FHIR_PACKAGE_NAME = /^[a-z][a-zA-Z0-9-]*\.([a-z][a-zA-Z0-9-]*\.?)*/
      HTTP_URI = %r{^https?:(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?}
      FILE_URI = %r{^file://(.+)}
      HTML_SUFFIX = %r{[^/]*\.x?html?$}

      class Error < StandardError
      end

      def ig_path
        File.join('lib', library_name, 'igs')
      end

      def load_ig(ig_input, idx = nil)
        case ig_input
        when FHIR_PACKAGE_NAME
          thor_get_ig ig_registry_url(ig_input), idx
        when HTTP_URI
          thor_get_ig ig_http_url(ig_input), idx
        when FILE_URI
          thor_get_ig ig_input[7..-1], idx
        else
          raise Error, <<~FAILED_TO_LOAD
            Could not find implementation guide: #{ig_input}
            Put its package.tgz file directly in #{ig_path}
          FAILED_TO_LOAD
        end
      end

      # private

      def thor_get_ig(uri, idx = nil)
        say_unless_quiet "Downloading IG from #{uri}"
        get(uri, ig_file(idx))
      end

      def ig_file(suffix = nil)
        File.join(ig_path, suffix ? "package_#{suffix}.tgz" : 'package.tgz')
      end

      def ig_registry_url(ig_npm_style)
        unless ig_npm_style.include? '@'
          raise Error, <<~NO_VERSION
            No IG version specified for #{ig_npm_style}; you must specify one with '@'. I.e: hl7.fhir.us.core@7.0.0-ballot
          NO_VERSION
        end

        package_name, version = *ig_npm_style.split('@')
        "https://packages.simplifier.net/#{package_name}/-/#{package_name}-#{version}.tgz"
      end

      def ig_http_url(ig_page_url)
        unless ig_page_url.end_with? 'package.tgz'
          ig_page_url += 'package.tgz' if ig_page_url.end_with? '/'
          ig_page_url = ig_page_url.gsub(HTML_SUFFIX, 'package.tgz') if ig_page_url.match? HTML_SUFFIX
        end
        ig_page_url
      end
    end
  end
end
