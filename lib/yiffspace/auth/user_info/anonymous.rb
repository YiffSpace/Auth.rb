# frozen_string_literal: true

require("singleton")

module YiffSpace
  module Auth
    class UserInfo
      class Anonymous
        include(::Singleton)

        %i[id user discord avatar].each do |attr|
          define_method(attr) { |*, **| raise(NotImplementedError, "#{attr} is not present on anonymous user") }
        end

        def username
          "anonymous"
        end

        def display_name
          "Anonymous"
        end

        def avatar
          nil
        end

        def avatar_url
          nil
        end

        def banner
          nil
        end

        def banner_url
          nil
        end

        def anonymous?
          true
        end

        # this feels wrong, but it hopefully shouldn't break anything
        def present?
          false
        end

        def blank?
          true
        end

        def serializable_hash(*)
          nil
        end

        def to_session
          serializable_hash
        end

        def self.from_json(*)
          Anonymous.instance
        end

        def self.from_session(data)
          return nil if data.blank?

          from_json(data)
        end
      end
    end
  end
end
