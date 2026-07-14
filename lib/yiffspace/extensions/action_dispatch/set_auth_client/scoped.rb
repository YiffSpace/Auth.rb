# frozen_string_literal: true

module YiffSpace
  module Extensions
    module ActionDispatch
      module SetAuthClient
        module Scoped
          def yiffspace_set_auth_client(name, &)
            constraints(Auth::SetClientName.new(name), &)
          end
        end
      end
    end
  end
end
