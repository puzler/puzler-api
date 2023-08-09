# frozen_string_literal: true

module Mutations
  module Auth
    class SignOut < AuthMutation
      argument :token, String, required: true, description: 'The JWT to invalidate'

      description 'Signs Out by invalidating the current JWT'
      authenticated true

      def resolve(token:)
        payload = User.decode_jwt(token)
        return error('Invalid Token') if payload.nil?
        return error('Invalid Token') if payload[:sub] != current_user.id

        invalidator = JwtDenylist.new(
          jti: payload[:jti],
          exp: DateTime.strptime(payload[:exp].to_s, '%s')
        )
        return error('Unable to Invalidate Token') unless invalidator.save

        { success: true }
      end
    end
  end
end
