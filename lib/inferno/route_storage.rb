module Inferno
  # @private
  module RouteStorage
    def routes
      @routes ||= []
    end
  end

  extend RouteStorage
end
