module Inferno
  module Utils
    # @api private
    module MarkdownFormatter
      def format_markdown(markdown)
        natural_indent = markdown.lines.collect { |l| l.index(/[^ ]/) }.select { |l| !l.nil? && l.positive? }.min || 0
        unindented_markdown = markdown.lines.map { |l| l[natural_indent..-1] || "\n" }.join
      end
    end
  end
end
