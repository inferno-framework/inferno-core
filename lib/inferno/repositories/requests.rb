module Inferno
  module Repositories
    class Requests < Repository
      include Import[headers_repo: 'inferno.repositories.headers']

      def create(params)
        request = self.class::Model.create(db_params(params))

        request_headers = (params[:request_headers] || []).map do |header_hash|
          request.add_header(header_hash.merge(type: 'request'))
        end
        response_headers = (params[:response_headers] || []).map do |header_hash|
          request.add_header(header_hash.merge(type: 'response'))
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
        many_to_many :result,
                     class: 'Inferno::Repositories::Results::Model',
                     join_table: :requests_results,
                     left_key: :requests_id,
                     right_key: :results_id
        many_to_many :headers,
                     class: 'Inferno::Repositories::Headers::Model',
                     join_table: :requests_unique_headers,
                     left_key: :requests_id,
                     right_key: :unique_headers_id,
                     adder: :add_header

        def before_create
          self.id = SecureRandom.uuid
          time = Time.now
          self.created_at ||= time
          self.updated_at ||= time
          super
        end

        def add_header(header_hash)
          Headers::Model.find_or_create(
            type: header_hash[:type],
            name: header_hash[:name],
            value: header_hash[:value]
          ).tap do |header|
            Inferno::Application['db.connection'][:requests_unique_headers].insert(
              unique_headers_id: header.id,
              requests_id: index
            )
          end
        end
      end
    end
  end
end
