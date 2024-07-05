module FHIR
  class Client
    attr_accessor :oauth_credentials, :auth_info

    def need_to_refresh?
      auth_info&.need_to_refresh?.present? || oauth_credentials&.need_to_refresh?.present?
    end

    def able_to_refresh?
      auth_info&.able_to_refresh?.present? || oauth_credentials&.able_to_refresh?.present?
    end
  end
end
