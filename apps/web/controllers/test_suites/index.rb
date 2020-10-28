module Inferno
  module Web
    module Controllers
      module TestSuites
        class Index < Controller
          def call(_params)
            self.body = serialize(repo.all, view: :summary)
          end
        end
      end
    end
  end
end
