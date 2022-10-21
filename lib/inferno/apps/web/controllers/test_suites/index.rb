module Inferno
  module Web
    module Controllers
      module TestSuites
        class Index < Controller
          def handle(_req, res)
            res.body = serialize(repo.all, view: :summary)
          end
        end
      end
    end
  end
end
