require_relative '../../serializers/requirement'

module Inferno
  module Web
    module Controllers
      module Requirements
        class Index < Controller
          def handle(_req, res)
            res.body = serialize(repo.all)
          end
        end
      end
    end
  end
end
