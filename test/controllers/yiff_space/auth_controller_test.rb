# frozen_string_literal: true

require("test_helper")

module YiffSpace
  class AuthControllerTest < ActionDispatch::IntegrationTest
    test("auth engine loads its routes") do
      assert_equal(
        { controller: "yiff_space/auth/root", action: "cb" },
        YiffSpace::Auth::Engine.routes.recognize_path("/cb", method: :get),
      )
      assert_recognizes({ controller: "yiff_space/auth/root", action: "cb" }, "/auth/cb")
    end

    test("auth controller exposes session helper methods through helpers") do
      helper_methods = YiffSpace::Auth::ApplicationController._helpers.instance_methods

      assert_includes(helper_methods, :auth)
      assert_includes(helper_methods, :auth=)
      assert_includes(helper_methods, :auth?)
      assert_includes(helper_methods, :user)
      assert_includes(helper_methods, :user=)
      assert_includes(helper_methods, :user?)
      assert_includes(helper_methods, :logged_in?)
      assert_includes(helper_methods, :require_auth)
      assert_includes(helper_methods, :has_permission?)
      assert_includes(helper_methods, :auth_client_config)

      assert_not_includes(helper_methods, :generate_state!)
      assert_not_includes(helper_methods, :return_path)
      assert_not_includes(helper_methods, :return_path=)
    end

    test("scoped helper can be included without exposing unprefixed methods") do
      controller = Class.new(ApplicationController) do
        include(YiffSpace::Auth::Helper::Scoped)
      end

      assert_includes(controller.instance_methods, :yiffspace_require_auth)
      assert_not_includes(controller.instance_methods, :require_auth)
      assert_includes(controller.private_instance_methods, :require_auth)

      assert_respond_to(controller, :yiffspace_set_client_name)
      assert_not_respond_to(controller, :set_client_name)
      assert_includes(controller.private_methods, :set_client_name)
    end
  end
end
