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
  APPLICATION_NAME = "SAGE"
  SCOPES = [
      'https://www.googleapis.com/auth/drive.metadata.readonly',
  ]

  ##
  # Create a new API Client.
  #
  # @param [String] access_code
  # Optional access code, if one has already been obtained.
  # @return [Google::APIClient] client
  # A configured API Client.
  def self.create_api_client(access_token = nil)

    # Create new client.
    client = Google::APIClient.new(application_name: APPLICATION_NAME)

    # Configure client.
    client.authorization.client_id = CLIENT_ID
    client.authorization.client_secret = CLIENT_SECRET
    client.authorization.redirect_uri = REDIRECT_URI
    client.authorization.scope = SCOPES
    client.authorization.access_token = access_token

    # Return client.
    return client
  end

  ##
  # Generate an authorization URL.
  #
  # @param [String] state
  #   State for the authorization URL.
  # @return [String]
  #  Authorization URL to redirect the user to.
  def self.get_authorization_url(state)

    # Create new client.
    client = create_api_client

    # Generate and return authorisation uri.
    return client.authorization.authorization_uri(
      :state => state
    ).to_s
  end

  ##
  # Exchange an authorization code for OAuth 2.0 credentials.
  #
  # @param [String] authorization_code
  #   Authorization code to exchange for OAuth 2.0 credentials.
  # @return [Signet::OAuth2::Client]
  #  OAuth 2.0 credentials.
  def self.exchange_code(authorization_code)

    # Create new client.
    client = create_api_client

    # Configure client.
    client.authorization.code = authorization_code

    # Fetch authorization.
    begin
      client.authorization.fetch_access_token!
      return client.authorization
    rescue Signet::AuthorizationError
      raise CodeExchangeError.new
    end
  end

  ##
  # Import the contents of a Google Drive folder into the current project.
  #
  # @param [String] folder
  #   Shareable link to the Google Drive folder.
  # @param [Integer] project_id
  #   ID of the project to import the files into.
  # @param [String] access_token
  #   Access token to be used for this operation.
  def self.import_drive_folder(folder, project_id, access_token)

    # Get the folder's file ID.
    drive_folder = %r{\Ahttps://drive.google.com/open\?id=(?<file_id>\w+)\z}
    data = drive_folder.match folder

    # Check for ID errors.
    if data
      folder_id = data[:file_id]
    else
      raise FileIdError
    end

    # Create Google API client.
    client = create_api_client(access_token)

    # Create Drive API client.
    drive = client.discovered_api('drive', 'v2')

    # Configure parameters.
    parameters = {
      folderId: folder_id,
      pageToken: nil
    }
    children = []

    # Fetch pages of children.
    begin

      # Query Google Drive for the folder's metadata.
      result = client.execute(
        :api_method => drive.children.list,
        :parameters => parameters
      )

      # Check for error.
      if result.status != 200
        raise FileListError
      end

      # Get the folder's children.
      children << result.data.items

      # Update page token.
      parameters[:pageToken] = result.next_page_token

    end while !(parameters[:pageToken].nil?)

    # For each child:
    children.flatten!.each do |child|

      # Add the file.
      DigitalObject.create(
        project_id: project_id,
        location: "https://docs.google.com/uc?id=#{child['id']}"
      )
    end

    # Return notice.
    if children.count == 0
      return "No files were found in the specified Google Drive folder."
    else
      return "#{children.count} files were successfully imported."
    end
  end
end

##
# Error raised when a code exchange has failed.
class CodeExchangeError < StandardError
end

##
# Error raised when a folder cannot be listed.
class FileListError < StandardError
end

##
# Error raised when an id cannot be extracted for a Google resource.
class FileIdError < StandardError
end
