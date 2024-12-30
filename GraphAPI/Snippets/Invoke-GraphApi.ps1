# $TenantID = ""
# $ClientID = ""
# $ClientSecret = ""
# $GroupID = ""

# Function to invoke the Graph API
function Invoke-GraphApi {
    param (
        [string]$ApiEndpoint,
        [string]$Method = 'GET',
        [string]$Body = $null,
        [string]$Version = 'v1.0',
        [string]$ContentType = 'application/json',
        [string]$ConsistencyLevel = $null
    )

    # Set the base URL for the Graph API
    $baseUrl = "https://graph.microsoft.com/$Version"

    # Authorize with the dynamically obtained access token
    $authorization = @{
        'Authorization' = "Bearer $GraphAPIAccessToken"
        'Content-Type' = 'application/json'
        'ConsistencyLevel' = $ConsistencyLevel
    }

    # Build the full URL
    $url = "$baseUrl$ApiEndpoint"

    # Execute the HTTP call based on the specified method
    $response = Invoke-RestMethod -Uri $url -Headers $authorization -Method $Method -Body $Body -ContentType $ContentType

    # Return the response
    $response
}

# Build the authorization header
$tokenUrl = "https://login.microsoftonline.com/$TenantID/oauth2/token"
$GraphAPIBody = @{
    'resource' = 'https://graph.microsoft.com'
    'client_id' = $ClientId
    'client_secret' = $ClientSecret
    'grant_type' = 'client_credentials'
}

# Obtain the access token
$GraphAPItokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -ContentType "application/x-www-form-urlencoded" -Body $GraphAPIBody
$GraphAPIAccessToken = $GraphAPItokenResponse.access_token

# Example of invoke via params
    
    # Parameters to get all managed devices for SerialNumber comparison
    $GETGroupListTransitiveMemParams = @{
        ApiEndpoint = "/groups/$groupID/transitivemembers/microsoft.graph.user?`$count=true&`$select=id,DisplayName,AccountEnabled"
        Method      = "GET"
        ConsistencyLevel  = "eventual"
    }

    $AllTransitiveMem = Invoke-GraphApi @GETGroupListTransitiveMemParams
