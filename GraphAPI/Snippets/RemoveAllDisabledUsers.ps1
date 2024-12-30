# Define script variables;
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

try {
    # Parameters to get all managed devices for SerialNumber comparison
    $GETGroupListTransitiveMemParams = @{
        ApiEndpoint = "/groups/$groupID/transitivemembers/microsoft.graph.user?`$count=true&`$select=id,DisplayName,AccountEnabled"
        Method      = "GET"
        ConsistencyLevel  = "eventual"  # Set the consistency level for the API call
    }

    # Invoke the Graph API to get all transitive members of the specified group
    $AllTransitiveMem = Invoke-GraphApi @GETGroupListTransitiveMemParams

    # Setup a list to store all disabled members in object form
    $MembersToDelete = @()

    # Loop through each transitive member to check if they are disabled
    foreach ($TransitiveMember in $AllTransitiveMem.value) {
        if (-not $TransitiveMember.accountEnabled) {
            # If the account is disabled, create a PSCustomObject to store the member's details
            $MembersToDelete += [PSCustomObject]@{
                Id = $TransitiveMember.id
                DisplayName = $TransitiveMember.displayName
            }
        }
    }

    # DELETE membership for each member in the MembersToDelete PSCustomObject
    foreach ($FilteredMember in $MembersToDelete) {
        # Parameters to invoke Graph API for removing the filtered members from the group
        $DELETEGroupListTransitiveMemParams = @{
            ApiEndpoint = "/groups/$groupID/members/$($FilteredMember.Id)/`$ref"
            Method      = "DELETE"  # Set the method to DELETE for removing members
        }

        # Invoke the Graph API to delete the member from the group
        Invoke-GraphApi @DELETEGroupListTransitiveMemParams
    }

} catch {
    # Handle any errors that occur during the try block
    Write-Host -ForegroundColor Red "An error occurred: $_"  # Output the error message
    Write-Host -ForegroundColor Red "Error Type: $($_.GetType().FullName)"  # Output the type of the error
    Write-Host -ForegroundColor Red "Error Message: `n$($_.Exception.Message)"  # Output the exception message
    Write-Host -ForegroundColor Red "Stack Trace: `n$($_.ScriptStackTrace)"  # Output the stack trace for debugging
}
