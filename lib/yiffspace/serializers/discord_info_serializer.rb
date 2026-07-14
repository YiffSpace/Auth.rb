# frozen_string_literal: true

require("active_job")

module YiffSpace
  module Serializers
    class DiscordInfoSerializer < ActiveJob::Serializers::ObjectSerializer
      def serialize(arg)
        super(**arg.serializable_hash)
      end

      def deserialize(arg)
        Auth::DiscordInfo.from_json(arg)
      end

      private

      def klass
        Auth::DiscordInfo
      end
    end
  end
end
