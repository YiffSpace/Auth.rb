# frozen_string_literal: true

YiffSpace::Auth::Engine.routes.draw do
  constraints(YiffSpace::Auth::SetClientName.default) do
    post(:webhook, controller: :webhook)
    get(:cb, controller: :root)
    get(:logout, controller: :root)
    get(:permissions, controller: :root)
    get(:debug, controller: :root) if YiffSpace::Auth.enable_debug_action?
    root(action: :show, controller: :root, as: :auth)
  end
end
