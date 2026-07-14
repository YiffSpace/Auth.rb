# frozen_string_literal: true

require("test_helper")

module YiffSpace
  module Auth
    class SessionSerializationTest < ActiveSupport::TestCase
      TEST_CLIENT_ID = "test-client-abc123"

      setup do
        YiffSpace::Auth.register(:_serialization_test) do |c|
          c.client_id = TEST_CLIENT_ID
        end
      end

      teardown do
        YiffSpace::Auth.instance_variable_get(:@clients).delete(:_serialization_test)
      end

      test("auth info round-trips through session data") do
        auth = AuthInfo.new(
          id:          "123",
          token:       build_token,
          permissions: %w[posts:read admin:users:read],
          roles:       %w[staff],
          client_id:   TEST_CLIENT_ID,
        )

        restored = AuthInfo.from_session(auth.to_session)

        assert_equal("123", restored.id)
        assert_equal(TEST_CLIENT_ID, restored.client_id)
        assert_equal(%w[staff], restored.roles)
        assert_equal(%w[posts:read admin:users:read], restored.permissions.values)
      end

      test("auth info serializes into session data") do
        auth = AuthInfo.new(
          id:          "123",
          token:       build_token,
          permissions: %w[posts:read admin:users:read],
          roles:       %w[staff],
          client_id:   TEST_CLIENT_ID,
        )

        data = auth.to_session

        assert_equal("123", data["id"])
        assert_equal(TEST_CLIENT_ID, data["client_id"])
        assert_equal(%w[posts:read admin:users:read], data["permissions"])
        assert_equal(%w[staff], data["roles"])
        assert(data.key?("token"), "expected session data to include serialized token")
      end

      test("user info round-trips through session data") do
        user = UserInfo.new(
          id:      "123",
          user:    build_user,
          discord: discord_attrs,
        )

        restored = UserInfo.from_session(user.to_session)

        assert_equal("123", restored.id)
        assert_equal("fox", restored.discord.username)
        assert_equal("123", restored.user["sub"])
      end

      test("anonymous auth info returns singleton from from_json") do
        restored = AuthInfo::Anonymous.from_json({})

        assert_same(AuthInfo::Anonymous.instance, restored)
        assert(restored.anonymous?)
      end

      test("anonymous user info returns singleton from from_json") do
        restored = UserInfo::Anonymous.from_json({})

        assert_same(UserInfo::Anonymous.instance, restored)
        assert(restored.anonymous?)
      end

      private

      def build_token
        { "iss" => "https://auth.yiff.space", "sub" => "123", "aud" => "https://gallery.furry.cool", "scope" => "posts:read admin:users:read" }
      end

      def build_user
        { "sub" => "123", "email" => "fox@example.com" }
      end

      def discord_attrs
        {
          "id"       => "123",
          "username" => "fox",
          "avatar"   => nil,
          "banner"   => nil,
        }
      end
    end
  end
end
