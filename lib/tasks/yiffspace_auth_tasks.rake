# frozen_string_literal: true

namespace(:yiffspace) do
  desc("Report and interactively remove duplicate/orphaned Logto users left behind by " \
       "get_or_create_user races. Prompts for confirmation before deleting each one. " \
       "Pass AUTH_CLIENT=name to use a registered auth client other than :default " \
       "(e.g. AUTH_CLIENT=yiffyapi_manage).")
  task(dedupe_users: :environment) do
    client_name = (ENV["AUTH_CLIENT"] || YiffSpace::Auth::DEFAULT_CLIENT_NAME).to_sym
    management = YiffSpace::Auth[client_name].logto_management

    puts("Scanning users via auth client #{client_name.inspect}...")
    result = YiffSpace::Utils::UserDeduper.scan(management)

    puts("\n#{result[:conflicts].size} discord id(s) with more than one linked user (ambiguous - not handled by this task, review manually):")
    result[:conflicts].each do |discord_id, group|
      puts("  discordId=#{discord_id}: #{group.map { |u| "#{u.id} (#{u.name})" }.join(', ')}")
    end

    puts("\n#{result[:unresolved_orphans].size} orphaned user(s) with no matching linked account (not handled by this task, review manually):")
    result[:unresolved_orphans].each do |user|
      puts("  #{user.id} (name=#{user.name}, avatar=#{user.data.avatar})")
    end

    puts("\n#{result[:deletable_orphans].size} confirmed duplicate(s) - orphan left by a losing get_or_create_user race:")
    if result[:deletable_orphans].empty?
      puts("  none found")
    else
      result[:deletable_orphans].each do |orphan, keeper|
        print("  delete #{orphan.id} (name=#{orphan.name}, avatar=#{orphan.data.avatar}), keeping #{keeper.id} (name=#{keeper.name}) for discordId=#{YiffSpace::Utils::UserDeduper.discord_id_for(keeper)}? [y/N] ")
        answer = $stdin.gets&.strip&.downcase
        if answer == "y"
          management.delete_user(orphan.id)
          puts("    deleted #{orphan.id}")
        else
          puts("    skipped")
        end
      end
    end
  end
end
