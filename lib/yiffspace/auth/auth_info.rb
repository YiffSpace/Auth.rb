# frozen_string_literal: true

module YiffSpace
  module Auth
    class AuthInfo
      attr_reader(:id, :token, :roles, :permissions, :client_id)

      # @param id String
      # @param roles Array(String)
      # @param permissions Array(String)
      # @param token LogtoClient::AccessTokenClaims
      # @param client_id String
      def initialize(id:, roles:, permissions:, token:, client_id:)
        raise(ArgumentError, "no id provided") if id.blank?
        raise(ArgumentError, "no token provided") if token.blank?
        raise(ArgumentError, "no client id provided") if client_id.blank?

        @id           = id
        @token        = token
        @roles        = Array(roles)
        @permissions  = Permissions.new(permissions, separator: YiffSpace::Auth.get_by_id(client_id).permissions_separator)
        @client_id    = client_id
      end

      def anonymous?
        false
      end

      # this feels wrong, but it hopefully shouldn't break anything
      def present?
        true
      end

      def blank?
        false
      end

      def has_permission?(name)
        permissions.include?(name.to_s)
      end

      def serializable_hash(*)
        {
          "id"          => id,
          "token"       => token.as_json,
          "roles"       => roles,
          "permissions" => permissions.values,
          "client_id"   => client_id,
        }
      end

      def to_session
        serializable_hash
      end

      def self.from_json(data)
        raise(ArgumentError, "invalid data") if data.blank?

        data = JSON.parse(data) if data.is_a?(String)
        data = ::YiffSpace::Utils::OpenHash.from(data)

        new(
          id:          data.id,
          token:       data.token,
          roles:       data.roles,
          permissions: data.permissions,
          client_id:   data.client_id,
        )
      end

      def self.from_session(data)
        return nil if data.blank?

        from_json(data)
      end
    end
  end
end
