# frozen_string_literal: true

module YiffSpace
  module Auth
    class ApiUser
      attr_reader(:data)

      def initialize(data)
        @data = Utils::OpenHash.from(data)
      end

      delegate(:id, :name, to: :data)

      def discord_id
        data.identities.discord.userId
      end

      def created_at
        Time.zone.at(data.createdAt)
      end

      def updated_at
        Time.zone.at(data.updatedAt)
      end

      def last_sign_in_at
        data.lastSignInAt.nil? ? nil : Time.zone.at(data.lastSignInAt)
      end

      def discord
        DiscordInfo.new(data.identities.discord.details.rawData)
      end

      def avatar
        Images::Avatar.get_for(discord_id, :discord)
      end

      def banner
        Images::Banner.get_for(discord_id, :discord)
      end
    end
  end
end
