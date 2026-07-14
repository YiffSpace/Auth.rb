# frozen_string_literal: true

module YiffSpace
  module Auth
    class RootController < ApplicationController
      include(Helper)

      before_action(:sync_auth_if_dirty!)

      def show
        client.sign_in(redirect_uri: auth_client_config.redirect_uri, post_redirect_uri: params[:path] || "/")
      end

      def cb
        client.handle_sign_in_callback(url: request.original_url)
        user = client.fetch_user_info
        self.user = UserInfo.new(id: user["identities"]["discord"]["userId"], user: user, discord: user["identities"]["discord"]["details"]["rawData"])
        token = client.access_token_claims(resource: auth_client_config.resource)
        self.auth = AuthInfo.new(id: user["identities"]["discord"]["userId"], token: token, permissions: token["scope"].split, roles: user["roles"], client_id: auth_client_config.client_id)
      end

      def permissions; end

      def logout
        client.sign_out(post_logout_redirect_uri: request.base_url)
        full_reset!
      end

      def debug
        return render("yiffspace/error", locals: { message: "Access Denied" }, status: :forbidden) unless YiffSpace::Auth.enable_debug_action?

        render(json: {
          env:     request.env.select { |env| env.start_with?("yiffspace.") },
          params:  params,
          session: session,
          client:  auth_client_config.as_json.merge(client_secret: "[REDACTED]"),
          user:    client.fetch_user_info,
          token:   client.access_token_claims(resource: auth_client_config.resource),
        })
      end

      private

      def client
        @client ||= auth_client_config.logto(self)
      end
    end
  end
end
