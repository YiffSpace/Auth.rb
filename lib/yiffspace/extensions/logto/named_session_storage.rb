# frozen_string_literal: true

require("logto/client")
require("securerandom")

module YiffSpace
  module Extensions
    module Logto
      # LogtoClient::SessionStorage (our superclass) stores its values - PKCE verifier, nonce,
      # state, and eventually the access/ID/refresh tokens themselves - directly in the Rails
      # session, which is more than enough on its own to blow the ~4KB cookie limit. The gem's
      # LogtoClient::RailsCacheStorage avoids the cookie but keys purely off app_id, with no
      # per-browser scoping, so concurrent sign-ins from different users would stomp on each
      # other's in-flight OAuth state. This keeps the per-browser scoping (still keyed off the
      # session) but only stores a small opaque token there, with the real value in Rails.cache.
      class NamedSessionStorage < LogtoClient::SessionStorage
        CACHE_KEY = "yiffspace:auth:logto_storage:%s"
        CACHE_TTL = 30.days

        def initialize(name, session, app_id: nil)
          super(session, app_id: app_id)
          @name = name
        end

        def get(key)
          token = @session[get_session_key(key)]
          return nil if token.blank?

          Rails.cache.read(format(CACHE_KEY, token))
        end

        def set(key, value)
          session_key = get_session_key(key)
          old_token = @session[session_key]
          Rails.cache.delete(format(CACHE_KEY, old_token)) if old_token.present?

          token = SecureRandom.hex(32)
          Rails.cache.write(format(CACHE_KEY, token), value, expires_in: CACHE_TTL)
          @session[session_key] = token
        end

        def remove(key)
          session_key = get_session_key(key)
          token = @session.delete(session_key)
          Rails.cache.delete(format(CACHE_KEY, token)) if token.present?
        end

        protected

        def get_session_key(key)
          "#{@name}_#{@app_id || 'default'}_#{key}"
        end
      end
    end
  end
end
