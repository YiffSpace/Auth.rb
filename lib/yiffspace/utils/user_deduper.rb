# frozen_string_literal: true

module YiffSpace
  module Utils
    # get_or_create_user is check-then-act (query Logto, then create) with no locking
    # of its own - two concurrent calls for a discord id that doesn't exist yet will
    # both create a user, and the loser's discord-identity-attach step fails once the
    # winner's identity claims it first. That leaves an identity-less "orphan" user
    # behind in Logto. This scans the whole user base to find those orphans (and any
    # other duplicate/ambiguous state) so they can be cleaned up.
    module UserDeduper
      # create_user sets a new user's avatar to the discord CDN URL for the discord id
      # it was created for, before the identity-attach step runs - so even an orphan
      # that never got its identity attached still reveals which discord id it was
      # meant for.
      AVATAR_ID_PATTERN = %r{cdn\.discordapp\.com/avatars/(\d+)/}

      module_function

      def discord_id_for(user)
        user.data.identities&.discord&.userId || avatar_discord_id_for(user)
      end

      def avatar_discord_id_for(user)
        match = user.data.avatar.to_s.match(AVATAR_ID_PATTERN)
        match && match[1]
      end

      def linked?(user)
        user.data.identities&.discord&.userId.present?
      end

      # Returns a hash with:
      # - :conflicts - discord id => users, for ids where more than one user has the
      #   identity actually attached. Ambiguous; always needs manual review, never
      #   auto-deleted.
      # - :deletable_orphans - [orphan, keeper] pairs, where orphan has no identity
      #   attached but its avatar points at a discord id claimed by exactly one other
      #   (linked) user. This is the confirmed race-loser case - safe to delete.
      # - :unresolved_orphans - users with no identity attached and no corresponding
      #   linked user (still mid-race, or the winner can't be identified). Reported
      #   only, never auto-deleted.
      def scan(management)
        users = management.list_users
        linked, unlinked = users.partition { |u| linked?(u) }

        by_discord_id = linked.group_by { |u| u.data.identities.discord.userId }
        conflicts = by_discord_id.select { |_id, group| group.length > 1 }

        deletable_orphans = []
        unresolved_orphans = []
        unlinked.each do |user|
          discord_id = avatar_discord_id_for(user)
          keeper = discord_id && by_discord_id[discord_id]
          if keeper&.length == 1
            deletable_orphans << [user, keeper.first]
          else
            unresolved_orphans << user
          end
        end

        { conflicts: conflicts, deletable_orphans: deletable_orphans, unresolved_orphans: unresolved_orphans }
      end
    end
  end
end
