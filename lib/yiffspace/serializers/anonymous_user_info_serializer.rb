# frozen_string_literal: true

require("active_job")

module YiffSpace
  module Serializers
    class AnonymousUserInfoSerializer < ActiveJob::Serializers::ObjectSerializer
      def serialize(_)
        super({})
      end

      def deserialize(_)
        Auth::UserInfo::Anonymous.instance
      end

      private

      def klass
        Auth::UserInfo::Anonymous
      end
    end
  end
end
