# frozen_string_literal: true

require("active_job")

module YiffSpace
  module Serializers
    class AuthInfoSerializer < ActiveJob::Serializers::ObjectSerializer
      def serialize(arg)
        super(**arg.serializable_hash)
      end

      def deserialize(arg)
        Auth::AuthInfo.from_json(arg)
      end

      private

      def klass
        Auth::AuthInfo
      end
    end
  end
end
