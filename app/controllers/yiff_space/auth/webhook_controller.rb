# frozen_string_literal: true

require("openssl")
require("active_support/security_utils")

module YiffSpace
  module Auth
    class WebhookController < ApplicationController
      skip_before_action(:verify_authenticity_token)

      HANDLED_EVENTS = %w[
        User.Roles.Updated
        User.SuspensionStatus.Updated
        User.Deleted
        Role.Scopes.Updated
      ].freeze
      DIRTY_FLAG_TTL = 24.hours

      def create
        unless verify_signature
          render(plain: "Unauthorized", status: :unauthorized)
          return
        end

        payload = JSON.parse(request.raw_post)
        event   = payload["event"]

        handle_event(event, payload) if HANDLED_EVENTS.include?(event)

        head(:ok)
      rescue JSON::ParserError
        render(plain: "Bad Request", status: :bad_request)
      end

      private

      def verify_signature
        secret = auth_client_config.logto_webhook_secret
        return true if secret.blank?

        received = request.headers["logto-signature-sha-256"].to_s
        expected = OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post)
        ActiveSupport::SecurityUtils.secure_compare(received, expected)
      end

      def handle_event(event, payload)
        data = payload["data"] || {}

        if event == "Role.Scopes.Updated"
          handle_role_scopes_updated(data)
        else
          user_id = data["id"]
          mark_dirty(user_id) if user_id.present?
        end
      end

      def handle_role_scopes_updated(data)
        role_id = data["id"]
        return if role_id.blank?

        management = auth_client_config.logto_management
        users      = management.get_users_with_role(role_id)
        users.each { |u| mark_dirty(u["id"]) }
      rescue StandardError => e
        Rails.logger.error("[YiffSpace::Auth::WebhookController] Role.Scopes.Updated fan-out failed: #{e.message}")
      end

      def mark_dirty(user_id)
        Rails.cache.write(format(Helper::DIRTY_FLAG_KEY, user_id), true, expires_in: DIRTY_FLAG_TTL)
      end
    end
  end
end
