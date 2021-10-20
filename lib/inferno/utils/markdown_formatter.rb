module Inferno
  module Utils
    # @private
    module MarkdownFormatter
      def format_markdown(markdown) # rubocop:disable Metrics/CyclomaticComplexity
        lines = markdown.lines

        return markdown if lines.any? { |line| line.match?(/^\S/) }

        natural_indent = lines.collect { |l| l.index(/[^ ]/) }.select { |l| !l.nil? && l.positive? }.min || 0
        markdown.lines.map { |l| l[natural_indent..] || "\n" }.join
      end
    end
  end
end
