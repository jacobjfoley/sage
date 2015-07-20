require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'
require 'fileutils'

class GoogleDriveUtils

  CLIENT_ID = ENV["GOOGLE_CLIENT_ID"]
  CLIENT_SECRET = ENV["GOOGLE_CLIENT_SECRET"]
  REDIRECT_URI = ENV["GOOGLE_REDIRECT_URI"]
  SCOPES = [
      'https://www.googleapis.com/auth/drive.metadata.readonly',
      'email',
      'profile',
  ]

  ##
  # Retrieve authorization URL.
  #
  # @param [String] state
  #   State for the authorization URL.
  # @return [String]
  #  Authorization URL to redirect the user to.
  def self.get_authorization_url(state)

    # Create new client.
    client = Google::APIClient.new

    # Configure client.
    client.authorization.client_id = CLIENT_ID
    client.authorization.redirect_uri = REDIRECT_URI
    client.authorization.scope = SCOPES

    # Generate and return authorisation uri.
    return client.authorization.authorization_uri(
      :state => state
    ).to_s
  end

  ##
  # Exchange an authorization code for OAuth 2.0 credentials.
  #
  # @param [String] authorisation_code
  #   Authorization code to exchange for OAuth 2.0 credentials.
  # @return [Signet::OAuth2::Client]
  #  OAuth 2.0 credentials.
  def self.exchange_code(authorisation_code)
    client = Google::APIClient.new(application_name: "SAGE")
    client.authorization.client_id = CLIENT_ID
    client.authorization.client_secret = CLIENT_SECRET
    client.authorization.code = authorisation_code
    client.authorization.redirect_uri = REDIRECT_URI

    begin
      client.authorization.fetch_access_token!
      return client.authorization
    rescue Signet::AuthorizationError
      raise CodeExchangeError.new(nil)
    end
  end

  ##############################################################################

  ##
  # Retrieved stored credentials for the provided user ID.
  #
  # @param [String] user_id
  #   User's ID.
  # @return [Signet::OAuth2::Client]
  #  Stored OAuth 2.0 credentials if found, nil otherwise.
  def get_stored_credentials(user_id)
    raise NotImplementedError, 'get_stored_credentials is not implemented.'
  end

  ##
  # Store OAuth 2.0 credentials in the application's database.
  #
  # @param [String] user_id
  #   User's ID.
  # @param [Signet::OAuth2::Client] credentials
  #   OAuth 2.0 credentials to store.
  def store_credentials(user_id, credentials)
    raise NotImplementedError, 'store_credentials is not implemented.'
  end


  ##
  # Send a request to the UserInfo API to retrieve the user's information.
  #
  # @param [Signet::OAuth2::Client] credentials
  #   OAuth 2.0 credentials to authorize the request.
  # @return [Google::APIClient::Schema::Oauth2::V2::Userinfo]
  #   User's information.
  def get_user_info(credentials)
    client = Google::APIClient.new
    client.authorization = credentials
    oauth2 = client.discovered_api('oauth2', 'v2')
    result = client.execute!(:api_method => oauth2.userinfo.get)
    user_info = nil
    if result.status == 200
      user_info = result.data
    else
      puts "An error occurred: #{result.data['error']['message']}"
    end
    if user_info != nil && user_info.id != nil
      return user_info
    end
    raise NoUserIdError, 'Unable to retrieve the e-mail address.'
  end

  ##
  # Retrieve credentials using the provided authorization code.
  #
  #  This function exchanges the authorization code for an access token and queries
  #  the UserInfo API to retrieve the user's e-mail address.
  #  If a refresh token has been retrieved along with an access token, it is stored
  #  in the application database using the user's e-mail address as key.
  #  If no refresh token has been retrieved, the function checks in the application
  #  database for one and returns it if found or raises a NoRefreshTokenError
  #  with an authorization URL to redirect the user to.
  #
  # @param [String] auth_code
  #   Authorization code to use to retrieve an access token.
  # @param [String] state
  #   State to set to the authorization URL in case of error.
  # @return [Signet::OAuth2::Client]
  #  OAuth 2.0 credentials containing an access and refresh token.
  def get_credentials(authorization_code, state)
    email_address = ''
    begin
      credentials = exchange_code(authorization_code)
      user_info = get_user_info(credentials)
      email_address = user_info.email
      user_id = user_info.id
      if credentials.refresh_token != nil
        store_credentials(user_id, credentials)
        return credentials
      else
        credentials = get_stored_credentials(user_id)
        if credentials != nil && credentials.refresh_token != nil
          return credentials
        end
      end
    rescue CodeExchangeError => error
      print 'An error occurred during code exchange.'
      # Drive apps should try to retrieve the user and credentials for the current
      # session.
      # If none is available, redirect the user to the authorization URL.
      error.authorization_url = get_authorization_url(email_address, state)
      raise error
    rescue NoUserIdError
      print 'No user ID could be retrieved.'
    end
    authorization_url = get_authorization_url(email_address, state)
    raise NoRefreshTokenError.new(authorization_url)
  end

  ##
  # Build a Drive client instance.
  #
  # @param [Signet::OAuth2::Client] credentials
  #   OAuth 2.0 credentials.
  # @return [Google::APIClient]
  #   Client instance
  def build_client(credentials)
    client = Google::APIClient.new
    client.authorization = credentials
    client = client.discovered_api('drive', 'v2')
    client
  end

  ##
  # Print a file's metadata.
  #
  # @param [Google::APIClient] client
  #   Authorized client instance
  # @param [String] file_id
  #   ID of file to print
  # @return nil
  def print_file(client, file_id)
    result = client.execute(
      :api_method => client.files.get,
      :parameters => { 'id' => file_id })
    if result.status == 200
      file = result.data
      puts "Title: #{file.data}"
      puts "Description: #{file.description}"
      puts "MIME type: #{file.mime_type}"
    elsif result.status == 401
        # Credentials have been revoked.
        # TODO: Redirect the user to the authorization URL.
        raise NotImplementedError, 'Redirect the user.'
    else
      puts "An error occurred: #{result.data['error']['message']}"
    end
  end
end

##
# Error raised when an error occurred while retrieving credentials.
class GetCredentialsError < StandardError
  ##
  # Initialize a NoRefreshTokenError instance.
  #
  # @param [String] authorize_url
  #   Authorization URL to redirect the user to in order to in order to request
  #   offline access.
  def initialize(authorization_url)
    @authorization_url = authorization_url
  end

  def authorization_url=(authorization_url)
    @authorization_url = authorization_url
  end

  def authorization_url
    return @authorization_url
  end
end

##
# Error raised when a code exchange has failed.
class CodeExchangeError < GetCredentialsError
end

##
# Error raised when no refresh token has been found.
class NoRefreshTokenError < GetCredentialsError
end

##
# Error raised when no user ID could be retrieved.
class NoUserIdError < StandardError
end
