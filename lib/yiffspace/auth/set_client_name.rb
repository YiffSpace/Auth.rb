# frozen_string_literal: true

module YiffSpace
  module Auth
    class SetClientName < Utils::SetEnvConstraint
      def initialize(value)
        super(CLIENT_NAME_ENV, value.to_sym)
      end

      def self.default
        new(DEFAULT_CLIENT_NAME)
      end
    end
  end
end
