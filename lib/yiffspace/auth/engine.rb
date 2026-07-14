# frozen_string_literal: true

require("rails")

module YiffSpace
  module Auth
    class Engine < ::Rails::Engine
      isolate_namespace(YiffSpace::Auth)
      config.root = File.expand_path("../../..", __dir__)

      initializer("yiffspace.auth.serializers") do
        ActiveSupport.on_load(:active_job) do
          ActiveJob::Serializers.add_serializers(
            Serializers::AnonymousAuthInfoSerializer,
            Serializers::AnonymousUserInfoSerializer,
            Serializers::AuthInfoSerializer,
            Serializers::DiscordInfoSerializer,
            Serializers::PermissionsSerializer,
            Serializers::UserInfoSerializer,
          )
        end
      end

      class << self
        def for(name)
          @instances              ||= {}
          @instances[name.to_sym] ||= begin
            subclass = Class.new(self)
            subclass.engine_name("yiffspace_auth_#{name}")
            # Inherit isolation settings that aren't copied from the parent class
            subclass.instance_variable_set(:@isolated, true)
            subclass.routes.default_scope = { module: "yiff_space/auth" }
            subclass.routes.draw do
              constraints(SetClientName.new(name)) do
                post(:webhook, controller: :webhook, action: :create)
                get(:cb, controller: :root)
                get(:logout, controller: :root)
                get(:permissions, controller: :root)
                get(:debug, controller: :root) if ::YiffSpace::Auth.enable_debug_action?
                root(action: :show, controller: :root, as: :auth)
              end
            end
            subclass
          end
        end
      end
    end
  end
end
