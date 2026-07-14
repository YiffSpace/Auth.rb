# frozen_string_literal: true

require("singleton")

module YiffSpace
  module Auth
    class AuthInfo
      class Anonymous
        include(::Singleton)

        %i[id token].each do |attr|
          define_method(attr) { |*, **| raise(NotImplementedError, "#{attr} is not present on anonymous auth") }
        end

        def roles
          []
        end

        def permissions
          Permissions.new([])
        end

        def has_permission?(*)
          false
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
