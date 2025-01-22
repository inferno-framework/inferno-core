require_relative '../../serializers/requirement'

module Inferno
  module Web
    module Controllers
      module Requirements
        class Show < Controller
          def handle(req, res)
            requirement = repo.find(req.params[:id])
            halt 404 if requirement.nil?

            res.body = serialize(requirement)
          end
        end
      end
    end
  end
end
