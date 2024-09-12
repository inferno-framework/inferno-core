module Inferno
  module DSL
    # This module contains methods to add test suite links which are displayed in the footer of the UI
    module Links
      DEFAULT_TYPES = {
        'report_issue' => 'Report Issue',
        'source_code' => 'Open Source',
        'download' => 'Download',
        'ig' => 'Implementation Guide'
      }.freeze

      # Set/get a list of links which are displayed in the footer of the UI.
      #
      # @param links [Array<Hash>] A list of Hashes for the links to be
      #   displayed. Each hash needs a `type:`, `label:`, and `url:` entry.
      #   Default types: `report_issue`, `source_code`, `download`, or `ig`.
      #
      # @return [Array<Hash>] an array of hashes or an empty array
      #
      # @example
      #   links [
      #     {
      #       type: 'report_issue',
      #       label: 'Report Issue',
      #       url: 'https://github.com/onc-healthit/onc-certification-g10-test-kit/issues/'
      #     },
      #     {
      #       type: 'source_code'
      #       label: 'Open Source',
      #       url: 'https://github.com/onc-healthit/onc-certification-g10-test-kit/'
      #     }
      #   ]
      def links(links = nil)
        @links ||= []
        return @links if links.nil?

        @links.concat(links)
      end

      # Add a link to the test suit links list.
      #
      # @param type [String] The type of the link. Default types: report_issue, source_code, download, or ig.
      #   Custom types are also allowed.
      # @param label [String] The label for the link, describing its purpose.
      # @param url [String] The URL the link points to.
      # @return [Array<Hash>] The updated array of links.
      #
      # @example
      #   add_link('source_code', 'Source Code', 'https://github.com/onc-healthit/onc-certification-g10-test-kit/')
      #   add_link('custom_type', 'Custom Link', 'https://custom-link.com')
      def add_link(type, label, url)
        links << { type:, label:, url: }
      end

      # Add a link to the source code repository.
      #
      # @param url [String] The URL to the source code repository.
      # @param label [String] (optional) A custom label for the link.
      # @return [Array<Hash>] The updated array of links.
      def source_code_url(url, label: nil)
        add_predefined_link('source_code', url, label)
      end

      # Add a link to the implementation guide.
      #
      # @param url [String] The URL to the implementation guide.
      # @param label [String] (optional) A custom label for the link.
      # @return [Array<Hash>] The updated array of links.
      def ig_url(url, label: nil)
        add_predefined_link('ig', url, label)
      end

      # Add a link to the latest release version of the test kit.
      #
      # @param url [String] The URL to the latest release version of the test kit.
      # @param label [String] (optional) A custom label for the link.
      # @return [Array<Hash>] The updated array of links.
      def download_url(url, label: nil)
        add_predefined_link('download', url, label)
      end

      # Add a link to report an issue in the footer of the UI.
      #
      # @param url [String] The URL for reporting an issue.
      # @param label [String] (optional) A custom label for the link.
      # @return [Array<Hash>] The updated array of links.
      def report_issue_url(url, label: nil)
        add_predefined_link('report_issue', url, label)
      end

      # @private
      def add_predefined_link(type, url, label = nil)
        label ||= DEFAULT_TYPES[type]
        raise ArgumentError, "Invalid link type: #{type}" unless label

        add_link(type, label, url)
      end
    end
  end
end
