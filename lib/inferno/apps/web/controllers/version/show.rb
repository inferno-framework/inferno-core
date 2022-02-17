module Inferno
  module Web
    module Controllers
      module Version
        class Show < Controller
          def call(params)
            version = Inferno::VERSION
           # halt 404 if version.nil?

            self.body = version || "COULD NOT FIND THE VERSION"
          end 
        end 
      end 
    end 
  end 
end 