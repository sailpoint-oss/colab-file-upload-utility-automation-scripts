param (
    [Parameter(Mandatory=$true)]
    [string]$mailBody,
    [Parameter(Mandatory=$true)]
    [string]$mailFrom,
    [Parameter(Mandatory=$true)]
    [string]$mailTo,
    [Parameter(Mandatory=$true)]
    [string]$mailCc,
    [Parameter(Mandatory=$true)]
    [string]$mailSubject
)

$toRecipients = @()
foreach ($email1 in $mailTo.Split(',')) {
    $toRecipients += @{
        "emailAddress" = @{
            "address" = $email1
        }
    }
}

$ccRecipients = @()
foreach ($email2 in $mailCc.Split(',')) {
    $ccRecipients += @{
        "emailAddress" = @{
            "address" = $email2
        }
    }
}
#Enterprise application details
$TenantId = "<TenantID>"
$AppId = "<App ID>"

$AppSecretEncrypted = Get-Content "<secret file path>" | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AppSecretEncrypted)
$AppSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$body = @{
	client_id = $AppId
    scope = "https://graph.microsoft.com/.default"
    client_secret = $AppSecret
    grant_type = "client_credentials"
}

$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token

$Headers = @{
	'Content-Type' = "application/json"
	'Authorization' = "Bearer $Token"
}


$MessageParams = @{
    "URI" = "https://graph.microsoft.com/v1.0/users/$mailFrom/sendMail"
    "Headers" = $Headers
    "Method" = "POST"
    "ContentType" = 'application/json'
    "Body" = @{
        "message" = @{
            "subject" = $mailSubject
            "body" = @{
                "contentType" = 'HTML'
                "content" = $mailBody
            }
            "toRecipients" = $toRecipients
            "ccRecipients"  = $ccRecipients
        }
    } | ConvertTo-JSON -Depth 6
}
#$MessageParams.Body
Invoke-RestMethod @MessageParams