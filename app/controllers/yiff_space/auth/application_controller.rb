# frozen_string_literal: true

module YiffSpace
  module Auth
    class ApplicationController < ::YiffSpace::ApplicationController
      include(Helper)

      helper(Helper)
    end
  end
end
