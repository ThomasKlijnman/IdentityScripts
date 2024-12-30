# Function to invoke the Azure Management API
function Invoke-AzureManagementApi {
    param (
        [string]$ApiEndpoint,
        [string]$Method = 'GET',
        [string]$Body = $null,
        [string]$Version = '2022-04-01',  # You can change this to the desired API version
        [string]$ContentType = 'application/json'
    )

    # Set the base URL for the Azure Management API
    $baseUrl = "https://management.azure.com/$ApiEndpoint`?api-version=$($Version)"

    # Authorize with the dynamically obtained access token
    $authorization = @{
        'Authorization' = "Bearer $AzureMGMTAccessToken"
        'Content-Type' = 'application/json'
    }

    # Execute the HTTP call based on the specified method
    $response = Invoke-RestMethod -Uri $baseUrl -Headers $authorization -Method $Method -Body $Body -ContentType $ContentType

    # Return the response
    $response
}

# Build the authorization header
$tokenUrl = "https://login.microsoftonline.com/$TenantID/oauth2/token"
$AzureMGMTBody = @{
    'resource' = 'https://management.azure.com'
    'client_id' = $ClientId
    'client_secret' = $ClientSecret
    'grant_type' = 'client_credentials'
}

# Obtain the access token
$AzureMGMTtokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -ContentType "application/x-www-form-urlencoded" -Body $AzureMGMTBody
$AzureMGMTAccessToken = $AzureMGMTtokenResponse.access_token

# Example of invoke with params

    # Setup the params
    $RoleAssignmentInvokeParams = @{
        ApiEndpoint = "$subscriptionId/providers/Microsoft.Authorization/roleAssignments"
        Method      = "GET"
        "Version"    = '2022-04-01'
    }

    # Invoke the API to get role assignments
    $roleAssignmentsResponse = Invoke-AzureManagementApi @RoleAssignmentInvokeParams
