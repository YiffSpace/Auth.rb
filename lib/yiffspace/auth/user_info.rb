# frozen_string_literal: true

module YiffSpace
  module Auth
    class UserInfo
      attr_reader(:id, :user, :discord)

      # @param id String
      # @param user LogtoCore::UserInfoResponse
      # @param discord Hash
      def initialize(id:, user:, discord:)
        raise(ArgumentError, "no id provided") if id.blank?
        raise(ArgumentError, "no user provided") if user.blank?

        @id        = id
        @user      = user
        @discord   = DiscordInfo.from_json(discord)
      end

      def anonymous?
        false
      end

      # this feels wrong, but it hopefully shouldn't break anything
      def present?
        true
      end

      def blank?
        false
      end

      def avatar(type = nil)
        type.present? ? Images::Avatar.get_for(id, type) : Images::Avatar.default_for(id)
      end

      def avatar_url(type = nil)
        avatar(type).url
      end

      def banner(type = nil)
        type.present? ? Images::Banner.get_for(id, type) : Images::Banner.default_for(id)
      end

      def banner_url(type = nil)
        banner(type).url
      end

      delegate(:username, to: :discord)

      def display_name
        discord.global_name
      end

      def serializable_hash(_options = {})
        {
          "id"      => id,
          "discord" => discord.serializable_hash,
          "user"    => user.as_json,
        }
      end

      def to_session
        serializable_hash.without("discord").merge(discord: discord.to_session)
      end

      def self.from_json(data)
        raise(ArgumentError, "invalid data") if data.blank?

        data = JSON.parse(data) if data.is_a?(String)
        data = ::YiffSpace::Utils::OpenHash.from(data)

        new(
          id:      data.id,
          discord: data.discord,
          user:    data.user,
        )
      end

      def self.from_session(data)
        return nil if data.blank?

        from_json(data)
      end
    end
  end
end
