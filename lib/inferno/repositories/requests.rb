module Inferno
  module Repositories
    class Requests < Repository
      include Import[headers_repo: 'inferno.repositories.headers']

      def create(params)
        request = self.class::Model.create(db_params(params))

        request_headers = (params[:request_headers] || []).map do |header|
          request.add_header(header.merge(request_id: request.index, type: 'request'))
        end
        response_headers = (params[:response_headers] || []).map do |header|
          request.add_header(header.merge(request_id: request.index, type: 'response'))
        end

        headers = (request_headers + response_headers).map { |header| headers_repo.build_entity(header.to_hash) }

        build_entity(
          request.to_hash
            .merge(headers:)
            .merge(non_db_params(params))
        )
      end

      def find(id)
        result =
          self.class::Model
            .where(id:)
            .select(*entity_class::SUMMARY_FIELDS)
            .to_a
        return nil if result.blank?

        build_entity(result.first.to_hash)
      end

      def find_full_request(id)
        result =
          self.class::Model
            .find(id:)
            .to_json_data(json_serializer_options)
            .deep_symbolize_keys!

        build_entity(result)
      end

      def find_named_request(test_session_id, name)
        results =
          self.class::Model
            .where(test_session_id:, name: name.to_s)
            .map { |model| model.to_json_data(json_serializer_options) }
        return nil if results.blank?

        result = results.reduce { |max, current| current['index'] > max['index'] ? current : max }
        result.deep_symbolize_keys!

        build_entity(result)
      end

      def requests_for_result(result_id)
        self.class::Model
          .order(:index)
          .where(result_id:)
          .select(*entity_class::SUMMARY_FIELDS)
          .to_a
          .map(&:to_hash)
          .map! { |result| build_entity(result) }
      end

      def json_serializer_options
        {
          include: :headers
        }
      end

      class Model < Sequel::Model(db)
        many_to_many :result, class: 'Inferno::Repositories::Results::Model', join_table: :requests_results,
                              left_key: :request_id, right_key: :result_id
        one_to_many :headers, class: 'Inferno::Repositories::Headers::Model', key: :request_id

        def before_create
          self.id = SecureRandom.uuid
          time = Time.now
          self.created_at ||= time
          self.updated_at ||= time
          super
        end
      end
    end
  end
end
