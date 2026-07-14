# frozen_string_literal: true

require("active_support/concern")

module YiffSpace
  module Auth
    module Helper
      extend(ActiveSupport::Concern)

      module ClassMethods
        def set_client_name(name) # rubocop:disable Naming/AccessorMethodName
          before_action do |controller|
            controller.request.env["yiffspace.auth.client_name"] = name
            if controller.respond_to?(:yiffspace_client_name=)
              controller.yiffspace_client_name = name
            elsif controller.respond_to?(:client_name=)
              controller.client_name = name
            elsif controller.respond_to?(:helpers)
              if controller.helpers.respond_to?(:yiffspace_client_name=)
                controller.helpers.yiffspace_client_name = name
              elsif controller.helpers.respond_to?(:client_name=)
                controller.helpers.client_name = name
              end
            end
          end
        end
      end

      def auth_raw
        session[auth_client_config.auth_session_key]
      end

      def auth
        return AuthInfo::Anonymous.instance if auth_raw.blank?

        AuthInfo.from_session(auth_raw)
      end

      def auth?
        auth_raw.present? && !auth.anonymous?
      end

      def auth=(value)
        value                                        = nil if value.is_a?(AuthInfo::Anonymous)
        session[auth_client_config.auth_session_key] = value&.to_session
      end

      def reset_auth!
        session.delete(auth_client_config.auth_session_key)
      end

      def user_raw
        session[auth_client_config.user_session_key]
      end

      def user
        return UserInfo::Anonymous.instance if user_raw.blank?

        UserInfo.from_session(user_raw)
      end

      def user?
        user_raw.present? && !user.anonymous?
      end

      def user=(value)
        value                                        = nil if value.is_a?(UserInfo::Anonymous)
        session[auth_client_config.user_session_key] = value&.to_session
      end

      def reset_user!
        session.delete(auth_client_config.user_session_key)
      end

      def full_reset!
        reset_auth!
        reset_user!
      end

      def require_auth(path)
        redirect_to(path) unless logged_in?
      end

      def logged_in?
        auth? && user?
      end

      def has_permission?(name)
        return false unless logged_in?

        auth.permissions.has?(name)
      end

      DIRTY_FLAG_KEY = "yiffspace:auth:dirty:%s"

      # Checks the dirty flag written by the Logto webhook handler. If set, re-fetches
      # the user's current roles and permissions from the Logto Management API and
      # rewrites the session — without waiting for the access token to expire.
      # Call this as a before_action in any controller that needs instant revocation.
      def sync_auth_if_dirty!
        return unless auth?

        flag_key = format(DIRTY_FLAG_KEY, auth.id)
        return unless Rails.cache.exist?(flag_key)

        Rails.cache.delete(flag_key)

        management = auth_client_config.logto_management
        api_user   = management.get_user_by_id(auth.id)

        if api_user.nil? || api_user.data["isSuspended"]
          full_reset!
          return
        end

        roles       = management.get_user_roles(auth.id)
        permissions = roles.flat_map { |role| management.get_role_scopes(role["id"]) }
                           .pluck("name")
                           .uniq

        self.auth = AuthInfo.new(
          id:          auth.id,
          token:       auth.token,
          roles:       roles.pluck("name"),
          permissions: permissions,
          client_id:   auth.client_id,
        )
      end

      def url_helpers
        YiffSpace::Auth::Engine.for(client_name).routes.url_helpers
      end

      # Returns the Auth::Client for the current request. In auth engine controllers this is
      # resolved from the routing default set by Engine.for; in host app controllers it falls
      # back to the default registered client. Override in your controller to choose a specific
      # client when multiple are registered.
      def auth_client_config
        client_name = self.client_name
        client_name.present? ? YiffSpace::Auth[client_name.to_sym] : YiffSpace::Auth.default
      end

      def client_name
        respond_to?(:request, true) && request.env[CLIENT_NAME_ENV]
      end

      def client_name=(value)
        request.env[CLIENT_NAME_ENV] = value.to_sym
      end

      module Scoped
        extend(ActiveSupport::Concern)
        include(Helper)

        included do
          private(*Helper.instance_methods(false))
          private_class_method(*Helper::ClassMethods.instance_methods(false))
        end

        Helper.instance_methods(false).each do |name|
          define_method("yiffspace_#{name}") { |*args, **kwargs, &block| send(name, *args, **kwargs, &block) }
        end

        module ClassMethods
          include(Helper::ClassMethods)

          Helper::ClassMethods.instance_methods(false).each do |name|
            define_method("yiffspace_#{name}") { |*args, **kwargs, &block| send(name, *args, **kwargs, &block) }
          end
        end
      end
    end
  end
end
