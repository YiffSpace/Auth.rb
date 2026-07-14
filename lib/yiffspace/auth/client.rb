# frozen_string_literal: true

require_relative("../core_ext/logto/named_session_storage")
require("httparty")

module YiffSpace
  module Auth
    class Client
      attr_accessor(:client_id, :client_secret, :scopes, :resource,
                    :redirect_uri, :server_url, :auth_session_key, :user_session_key,
                    :update_discord_images, :permissions_separator, :logto_webhook_secret)

      attr_reader(:name)

      def initialize(name)
        @name                    = name.to_sym
        @scopes                  = %i[openid offline_access profile roles identities custom_data]
        @redirect_uri            = "http://127.0.0.1:3000/auth/cb"
        @server_url              = "https://auth.yiff.space"
        @auth_session_key        = :"yiffspace_auth_#{name}"
        @user_session_key        = :"yiffspace_user_#{name}"
        @update_discord_images   = true
        @permissions_separator   = ":"
        @logto_webhook_secret    = nil
      end

      def logto(controller)
        LogtoClient.new(
          config:   LogtoClient::Config.new(
            endpoint:   server_url,
            app_id:     client_id,
            app_secret: client_secret,
            scopes:     scopes,
            resources:  [resource].compact,
          ),
          # Allow the client to redirect to other hosts (i.e. your Logto tenant)
          navigate: ->(uri) { controller.redirect_to(uri, allow_other_host: true) },
          # Controller has access to the session object
          storage:  LogtoClient::NamedSessionStorage.new("yiffspace", controller.session, app_id: @name),
        )
      end

      def logto_management
        @logto_management ||= LogtoManagementClient.new(self)
      end

      def fetch_discord_user(id)
        response = HTTParty.get("https://discord.com/api/v10/users/#{id}", { headers: { "Authorization" => "Bot #{YiffSpace.config.discord_bot_token}" } })
        return nil if response.code == 404
        raise("failed to fetch discord user: #{response.code} #{response.message}\n#{response.parsed_response.inspect}") if response.code != 200

        DiscordInfo.new(response.parsed_response)
      end
    end
  end
end
