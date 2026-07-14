# frozen_string_literal: true

require("active_support/core_ext/integer/time")
require("httparty")

module YiffSpace
  class LogtoManagementClient
    attr_reader(:auth)

    def initialize(auth)
      @auth = auth
    end

    def get_token # rubocop:disable Naming/AccessorMethodName
      if @_cached_token
        return @_cached_token if @_cache_expire_time > Time.current

        @_cached_token = nil
        @_cache_expire_time = nil
      end
      response = HTTParty.post("#{auth.server_url}/oidc/token", {
        body: {
          grant_type:    "client_credentials",
          client_id:     YiffSpace.config.logto_api_client_id,
          client_secret: YiffSpace.config.logto_api_client_secret,
          resource:      YiffSpace.config.logto_api_resource,
          scope:         "all",
        },
      })
      raise("failed to get access token: #{response.to_json}") unless response.key?("access_token")

      @_cached_token = response["access_token"]
      @_cache_expire_time = response["expires_in"].to_i.seconds.from_now
      response["access_token"]
    end

    def get_user(id)
      response = HTTParty.get("#{auth.server_url}/api/users?discordId=#{id}", { headers: { "Authorization" => "Bearer #{get_token}" } })
      return nil if response.code == 404 || (response.parsed_response.is_a?(Array) && response.parsed_response.empty?)
      raise("failed to get user: #{response.code} #{response.message}\n#{response.parsed_response.inspect}") if response.code != 200 || !response.parsed_response.is_a?(Array)

      Utils::TraceLogger.warn("LogtoManagementClient", "query discordId=#{id} returned more than one user:\n#{response.parsed_response.inspect}") if response.parsed_response.length > 1

      Auth::ApiUser.new(response.parsed_response.first)
    end

    def create_user(id)
      details = auth.fetch_discord_user(id)&.data
      raise("invalid discord user: #{id}") if details.blank?

      response = HTTParty.post("#{auth.server_url}/api/users", {
        headers: { "Authorization" => "Bearer #{get_token}", "Content-Type" => "application/json" },
        body:    { avatar: "https://cdn.discordapp.com/avatars/#{details['id']}/#{details['avatar']}", name: details["username"] }.to_json,
      })
      raise("failed to create user: #{response.code} #{response.message}\n#{response.parsed_response.inspect}") if response.code != 200

      response2 = HTTParty.put("#{auth.server_url}/api/users/#{response.parsed_response['id']}/identities/discord", {
        headers: { "Authorization" => "Bearer #{get_token}", "Content-Type" => "application/json" },
        body:    {
          userId:  details["id"],
          details: {
            id:      details["id"],
            name:    details["username"],
            avatar:  "https://cdn.discordapp.com/avatars/#{details['id']}/#{details['avatar']}",
            rawData: details,
          },
        }.to_json,
      })
      raise("failed to add discord identity: #{response2.code} #{response2.message}\n#{response2.parsed_response.inspect}") if response2.code != 201

      get_user(id) # force fresh fetch to ensure identity data is included properly
    end

    def get_or_create_user(id)
      get_user(id) || create_user(id)
    end

    # Pages through every user in the tenant. Used by maintenance tasks (e.g. the
    # dedupe_users rake task) - there's no discordId to filter by when scanning the
    # whole user base for duplicates/orphans.
    def list_users(page_size: 100)
      users = []
      page = 1
      loop do
        response = HTTParty.get("#{auth.server_url}/api/users", {
          headers: { "Authorization" => "Bearer #{get_token}" },
          query:   { page: page, page_size: page_size },
        })
        raise("failed to list users: #{response.code} #{response.message}\n#{response.parsed_response.inspect}") if response.code != 200 || !response.parsed_response.is_a?(Array)

        batch = response.parsed_response
        users.concat(batch.map { |u| Auth::ApiUser.new(u) })
        break if batch.length < page_size

        page += 1
      end
      users
    end

    def delete_user(logto_id)
      response = HTTParty.delete("#{auth.server_url}/api/users/#{logto_id}", { headers: { "Authorization" => "Bearer #{get_token}" } })
      return true if [204, 404].include?(response.code)

      raise("failed to delete user #{logto_id}: #{response.code} #{response.message}\n#{response.parsed_response.inspect}")
    end

    def get_user_by_id(logto_id)
      response = HTTParty.get("#{auth.server_url}/api/users/#{logto_id}", { headers: { "Authorization" => "Bearer #{get_token}" } })
      return nil if response.code == 404
      raise("failed to get user: #{response.code} #{response.message}\n#{response.parsed_response.inspect}") if response.code != 200

      Auth::ApiUser.new(response.parsed_response)
    end

    def get_user_roles(logto_id)
      response = HTTParty.get("#{auth.server_url}/api/users/#{logto_id}/roles", { headers: { "Authorization" => "Bearer #{get_token}" } })
      raise("failed to get user roles: #{response.code} #{response.message}\n#{response.parsed_response.inspect}") if response.code != 200

      response.parsed_response
    end

    def get_role_scopes(role_id)
      response = HTTParty.get("#{auth.server_url}/api/roles/#{role_id}/scopes", { headers: { "Authorization" => "Bearer #{get_token}" } })
      raise("failed to get role scopes: #{response.code} #{response.message}\n#{response.parsed_response.inspect}") if response.code != 200

      response.parsed_response
    end

    def get_users_with_role(role_id)
      response = HTTParty.get("#{auth.server_url}/api/roles/#{role_id}/users", { headers: { "Authorization" => "Bearer #{get_token}" } })
      raise("failed to get users with role: #{response.code} #{response.message}\n#{response.parsed_response.inspect}") if response.code != 200

      response.parsed_response
    end
  end
end
