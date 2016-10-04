module BotFramework
  class TokenValidator
    include HTTParty
    attr_accessor :headers

    OPEN_ID_CONFIG_URI = 'https://api.aps.skype.com/v1/.well-known/openidconfiguration'.freeze

    def initialize(headers)
      @headers = headers
    end

    def valid?
      true
    end

    private

    def open_id_config
      JSON.parse(self.class.get(OPEN_ID_CONFIG_URI).body)
    end

    def jwks_uri
      open_id_config['jwks_uri']
    end

    def valid_keys
      JSON.parse(self.class.get(jwks_uri).body)['keys']
    end

    def auth_header
      headers['Authorization']
    end

    def token
      auth_header.gsub('Bearer ', '')
    end

    def valid_?
      # The token was sent in the HTTP Authorization header with "Bearer" scheme
      auth_header.start_with? 'Bearer'
      # The token is valid JSON that conforms to the JWT standard (see references)
      JWT.decode token, nil, false
      # The token contains an issuer claim with value of https://api.botframework.com
      JWT.decode(token, nil, false).first['iss'] == 'https://api.botframework.com'
      # The token contains an audience claim with a value equivalent to your bot’s Microsoft App ID.
      JWT.decode(token, nil, false).first['aud'] == connector.app_id
      # The token has not yet expired. Industry-standard clock-skew is 5 minutes.
      # Should not raise JWT::ExpiredSignature
      # The token has a valid cryptographic signature with a key listed in the OpenId keys document retrieved in step 1, above.
      true
    end
  end
end
