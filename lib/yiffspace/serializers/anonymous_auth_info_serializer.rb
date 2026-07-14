# frozen_string_literal: true

require("active_job")

module YiffSpace
  module Serializers
    class AnonymousAuthInfoSerializer < ActiveJob::Serializers::ObjectSerializer
      def serialize(_)
        super({})
      end

      def deserialize(_)
        Auth::AuthInfo::Anonymous.instance
      end

      private

      def klass
        Auth::AuthInfo::Anonymous
      end
    end
  end
end
