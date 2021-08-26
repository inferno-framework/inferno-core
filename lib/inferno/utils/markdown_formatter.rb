module Inferno
  module Utils
    # @api private
    module MarkdownFormatter
      def format_markdown(markdown)
        natural_indent = markdown.lines.collect { |l| l.index(/[^ ]/) }.select { |l| !l.nil? && l.positive? }.min || 0
        markdown.lines.map { |l| l[natural_indent..] || "\n" }.join
      end
    end
  end
end
