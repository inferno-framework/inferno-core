module Inferno
  module Web
    module Serializers
      class Request < Serializer
        view :summary do
          field :id
          field :created_at, name: :timestamp
          field :verb
          field :url
          field :direction
          field :status
          field :result_id
        end

        view :full do
          include_view :summary

          field :created_at, name: :timestamp
          association :request_headers, blueprint: Header
          association :response_headers, blueprint: Header
          field :request_body
          field :response_body
        end
      end
    end
  end
end
