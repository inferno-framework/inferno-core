module SMART
  module TokenPayloadValidation
    STRING_FIELDS = ['access_token', 'token_type', 'scope', 'refresh_token'].freeze
    NUMERIC_FIELDS = ['expires_in'].freeze

    def validate_required_fields_present(body, required_fields)
      missing_fields = required_fields.select { |field| body[field].blank? }
      missing_fields_string = missing_fields.map { |field| "`#{field}`" }.join(', ')
      assert missing_fields.empty?,
             "Token exchange response did not include all required fields: #{missing_fields_string}."
    end

    def validate_token_type(body)
      assert body['token_type'].casecmp('bearer').zero?, '`token_type` must be `bearer`'
    end

    def check_for_missing_scopes(requested_scopes, body)
      expected_scopes = requested_scopes.split
      new_scopes = body['scope'].split
      missing_scopes = expected_scopes - new_scopes

      warning do
        missing_scopes_string = missing_scopes.map { |scope| "`#{scope}`" }.join(', ')
        assert missing_scopes.empty?, %(
          Token exchange response did not include all requested scopes.
          These may have been denied by user: #{missing_scopes_string}.
        )
      end
    end

    def validate_token_field_types(body)
      STRING_FIELDS
        .select { |field| body[field].present? }
        .each do |field|
        assert body[field].is_a?(String),
               "Expected `#{field}` to be a String, but found #{body[field].class.name}"
      end

      NUMERIC_FIELDS
        .select { |field| body[field].present? }
        .each do |field|
          assert body[field].is_a?(Numeric),
                 "Expected `#{field}` to be a Numeric, but found #{body[field].class.name}"
        end
    end
  end
end
