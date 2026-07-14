# frozen_string_literal: true

require("yiffspace")
require("zeitwerk")

loader = Zeitwerk::Loader.for_gem_extension(YiffSpace)
loader.ignore("#{__dir__}/core_ext")
loader.ignore("#{__dir__}/auth/engine.rb")
loader.setup

# Require the auth engine eagerly so it registers with Rails before the host app's
# active_support.initialize_per_engine_zeitwerk_loaders initializer runs. Without this,
# the engine is only loaded during route drawing (after Zeitwerk setup) and its
# app/controllers path is never added to the app's autoload roots.
require_relative("auth/engine") if defined?(Rails)

module YiffSpace
  module Auth
    CLIENT_NAME_ENV     = "yiffspace.auth.client_name"
    DEFAULT_CLIENT_NAME = :default

    @clients             = {}
    @enable_debug_action = false

    module_function

    def register(name, &block)
      client = Client.new(name)
      block&.call(client)
      @clients[name.to_sym] = client
      client
    end

    def [](name)
      @clients[name.to_sym] || raise(KeyError, "unknown auth client: #{name.inspect}")
    end

    def default
      @clients[DEFAULT_CLIENT_NAME] || raise("no default client configured")
    end

    def get_by_id(id)
      @clients.values.find { |c| c.client_id == id } || raise(ArgumentError, "unable to find client with id: #{id}")
    end

    def enable_debug_action?
      @enable_debug_action
    end

    def enable_debug_action!
      @enable_debug_action = true
    end

    def disable_debug_action!
      @enable_debug_action = false
    end
  end

  class Configuration
    # Logto Management API credentials (shared across all auth clients).
    attr_accessor(:logto_api_client_id, :logto_api_client_secret, :logto_api_resource)

    # Discord bot token used to look up Discord users (shared across all auth clients).
    attr_accessor(:discord_bot_token)

    def auth(&block)
      client = YiffSpace::Auth.register(Auth::DEFAULT_CLIENT_NAME) unless YiffSpace::Auth.instance_variable_get(:@clients).key?(Auth::DEFAULT_CLIENT_NAME)
      client ||= YiffSpace::Auth[Auth::DEFAULT_CLIENT_NAME]
      block&.call(client)
      client
    end

    def add_auth(name, &)
      YiffSpace::Auth.register(name, &)
    end

    def add_default_auth(&)
      add_auth(Auth::DEFAULT_CLIENT_NAME, &)
    end
  end
end
