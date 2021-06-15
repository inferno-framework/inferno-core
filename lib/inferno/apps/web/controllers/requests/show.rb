module Inferno
  module Web
    module Controllers
      module Requests
        class Show < Controller
          def call(params)
            request = repo.find_full_request(params[:id])
            halt 404 if request.nil?

            self.body = serialize(request, view: :full)
          end
        end
      end
    end
  end
end
