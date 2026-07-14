# frozen_string_literal: true

module YiffSpace
  module Auth
    class DiscordInfo
      # locale, mfa_enabled, and premium_type are not present for legacy users backfilled from api data,
      # we don't need that data either way
      ATTRIBUTES = %i[id flags avatar banner username global_name public_flags discriminator].freeze
      attr_reader(:data, *ATTRIBUTES)

      def initialize(options = {}, **kwargs)
        @data = options.merge(kwargs).with_indifferent_access
        ATTRIBUTES.each do |attr|
          instance_variable_set("@#{attr}", @data[attr])
        end

        return unless YiffSpace.config.auth.update_discord_images

        last_avatar = Rails.cache.fetch("yiffspace:auth:discord_avatar_update:#{id}")
        last_banner = Rails.cache.fetch("yiffspace:auth:discord_banner_update:#{id}")

        if last_avatar != avatar
          Rails.cache.write("yiffspace:auth:discord_avatar_update:#{id}", avatar, expires_in: 30.days)
          update_avatar
        end

        return unless last_banner != banner

        Rails.cache.write("yiffspace:auth:discord_banner_update:#{id}", banner, expires_in: 30.days)
        update_banner
      end

      def update_avatar
        Images::Avatar.get_for(id, :discord).update(avatar)
      end

      def update_banner
        Images::Banner.get_for(id, :discord).update(banner)
      end

      def serializable_hash(*)
        ATTRIBUTES.to_h { |key| [key.to_s, instance_variable_get("@#{key}")] }
      end

      def to_session
        serializable_hash
      end

      def self.from_json(data)
        raise(ArgumentError, "invalid data") if data.blank?

        data = JSON.parse(data) if data.is_a?(String)
        data = ::YiffSpace::Utils::OpenHash.from(data)

        new(data)
      end

      def self.from_session(data)
        return nil if data.blank?

        from_json(data)
      end
    end
  end
end
