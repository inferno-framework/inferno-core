module Inferno
  module Web
    module Controllers
      module Requests
        class Show < Controller
          def handle(req, res)
            request = repo.find_full_request(req.params[:id])
            halt 404 if request.nil?

            update_request_headers(request) if safe_mode?

            res.body = serialize(request, view: :full)
          end

          private

          def safe_mode?
            ENV['SAFE_MODE'] == 'true'
          end

          def update_request_headers(request)
            request.request_headers.each do |header|
              header.value = 'PROTECTED' if header.name.downcase == 'authorization'
            end
          end
        end
      end
    end
  end
end
