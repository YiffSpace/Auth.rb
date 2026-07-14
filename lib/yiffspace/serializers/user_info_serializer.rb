# frozen_string_literal: true

require("active_job")

module YiffSpace
  module Serializers
    class UserInfoSerializer < ActiveJob::Serializers::ObjectSerializer
      def serialize(arg)
        super(**arg.serializable_hash)
      end

      def deserialize(arg)
        Auth::UserInfo.from_json(arg)
      end

      private

      def klass
        Auth::UserInfo
      end
    end
  end
end
