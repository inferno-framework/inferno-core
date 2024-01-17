module Inferno
  module Repositories
    class Requests < Repository
      include Import[
                headers_repo: 'inferno.repositories.headers',
                tags_repo: 'inferno.repositories.tags'
              ]

      def create(params)
        request = self.class::Model.create(db_params(params))

        headers = create_headers(request, params)

        params[:tags]&.each do |tag|
          request.add_tag(tag)
        end

        build_entity(
          request.to_hash
            .merge(headers:)
            .merge(non_db_params(params))
        )
      end

      def create_headers(request, params)
        request_headers = (params[:request_headers] || []).map do |header|
          request.add_header(header.merge(request_id: request.index, type: 'request'))
        end
        response_headers = (params[:response_headers] || []).map do |header|
          request.add_header(header.merge(request_id: request.index, type: 'response'))
        end

        (request_headers + response_headers).map { |header| headers_repo.build_entity(header.to_hash) }
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

      def tagged_requests(test_session_id, tags)
        self.class::Model
          .tagged_requests(test_session_id, tags)
          .to_a
          .map! do |request|
            build_entity(
              request
                .to_json_data(json_serializer_options)
                .deep_symbolize_keys!
            )
          end
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
          include: [:headers, :tags]
        }
      end

      class Model < Sequel::Model(db)
        many_to_many :result,
                     class: 'Inferno::Repositories::Results::Model',
                     join_table: :requests_results,
                     left_key: :request_id,
                     right_key: :result_id
        many_to_many :tags,
                     class: 'Inferno::Repositories::Tags::Model',
                     join_table: :requests_tags,
                     left_key: :requests_id,
                     right_key: :tags_id,
                     adder: :add_tag
        one_to_many :headers,
                    class: 'Inferno::Repositories::Headers::Model',
                    key: :request_id

        def before_create
          self.id = SecureRandom.uuid
          time = Time.now
          self.created_at ||= time
          self.updated_at ||= time
          super
        end

        def add_tag(tag_name)
          tag = Tags::Model.find_or_create(name: tag_name)

          Inferno::Application['db.connection'][:requests_tags].insert(
            tags_id: tag.id,
            requests_id: index
          )
        end

        def self.tagged_requests_sql
          # Find all the requests for the current session which:
          # - match all supplied tags
          # - are the from the most recent test run for each runnable
          <<~SQL.gsub(/\s+/, ' ').freeze
            select final_requests.*
            from (
                select uncounted_requests.request_id request_id
                from (
                        select r.id request_id, t.id tag_id from requests r
                        inner join requests_tags rt on r."index" = rt.requests_id
                        inner join tags t on rt.tags_id = t.id
                        where r.test_session_id = :test_session_id
                        and r.result_id in (
                        SELECT a.id FROM results a
                                WHERE a.test_session_id = r.test_session_id
                                AND a.id IN  (
                                SELECT id
                                FROM results b
                                WHERE (b.test_session_id = a.test_session_id AND b.test_id = a.test_id) OR
                                        (b.test_session_id = a.test_session_id AND b.test_group_id = a.test_group_id) OR
                                        (b.test_session_id = a.test_session_id AND b.test_suite_id = a.test_suite_id)
                                ORDER BY updated_at DESC
                                LIMIT 1
                                )
                        )
                        and t.name in :tags
                        group by r.id, t.id
                    ) as uncounted_requests
                    group by uncounted_requests.request_id
                    having count(*) = :tag_count
                ) as matched_requests
            inner join requests final_requests on final_requests.id = matched_requests.request_id
            where final_requests.test_session_id = :test_session_id
            order by final_requests."index"
          SQL
        end

        def self.tagged_requests(test_session_id, tags)
          fetch(tagged_requests_sql, test_session_id:, tags:, tag_count: tags.length)
        end
      end
    end
  end
end
