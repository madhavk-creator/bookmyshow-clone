require "jwt"

module JsonWebToken
  ALGORITHM = "HS256"
  EXPIRY    = 24.hours

  module_function

  # @param payload [Hash]
  # @param expiry  [ActiveSupport::Duration]
  # @return [String] signed JWT
  def encode(payload, expiry: EXPIRY)
    payload = payload.merge(
      iat: Time.current.to_i,
      exp: expiry.from_now.to_i
    )
    JWT.encode(payload, secret, ALGORITHM)
  end

  # @param token [String]
  # @return [HashWithIndifferentAccess]
  # @raise [JsonWebToken::Error] on any failure
  def decode(token)
    payload = JWT.decode(token, secret, true, algorithm: ALGORITHM).first
    payload.with_indifferent_access
  rescue JWT::ExpiredSignature
    raise Error, "Token has expired"
  rescue JWT::DecodeError => e
    raise Error, "Invalid token: #{e.message}"
  end

  def secret
    Rails.application.credentials.fetch(:jwt_secret_key, ENV["JWT_SECRET_KEY"])
  end

  class Error < StandardError; end
end
