# frozen_string_literal: true

require_relative("../../../extensions/action_dispatch/set_auth_client/scoped")

module ActionDispatch
  module Routing
    class Mapper
      module Scoping
        include(YiffSpace::Extensions::ActionDispatch::SetAuthClient::Scoped)
      end
    end
  end
end
