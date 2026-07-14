# frozen_string_literal: true

require("logto/client")

module YiffSpace
  module Extensions
    module Logto
      class NamedSessionStorage < LogtoClient::SessionStorage
        def initialize(name, session, app_id: nil)
          super(session, app_id: app_id)
          @name = name
        end

        protected

        def get_session_key(key)
          "#{@name}_#{@app_id || 'default'}_#{key}"
        end
      end
    end
  end
end
