module Inferno
  module Web
    module Controllers
      module Requests
        class Show < Controller
          def handle(req, res)
            request = repo.find_full_request(req.params[:id])
            halt 404 if request.nil?

            res.body = serialize(request, view: :full)
          end
        end
      end
    end
  end
end
