#log file info
$logDate = Get-Date -UFormat "%Y%m%d"
$logFile = "<path>\File_Upload_Utility_$logDate.log"
$propertiesFile = "<path>\FUU.properties"

#save logging files to a separate txt file

function Write-Log {
    param (
        [string]$Message,
        [string]$Level
    )
    $FormattedMessage = "[$(Get-Date)] [$Level] $Message"
    Write-Output $FormattedMessage | Out-File -Append -FilePath $logFile
}
  
Write-Log -Message "File Upload Utility ------ Start" -Level "INFO"

Write-Log -Message "Loading FUU Config" -Level "INFO"

$properties = @{}

# Read the properties file
try {
    $lines = Get-Content -Path $propertiesFile -ErrorAction Stop
} catch {
    Write-Log -Message "Failed to read the properties file: $_" -Level "ERROR"
    exit 1
}

Write-Log -Message "Loading FUU Config --- Completed" -Level "INFO"

# Parse each line in the file
foreach ($line in $lines) {
    # Ignore empty lines and comments
    if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith("#")) {
        $key, $value = $line -split "=", 2
        $key = $key.Trim()
        $value = $value.Trim()
        $properties[$key] = $value
    }
}

$tenant_url = $properties["tenant_url"]
$client_id = $properties["client_id"]
$jarPath = $properties["jar_path"]
$filePath = $properties["file_path"]
$secret = $properties["secret"]
$mailFrom = $properties["from"]
$to_recipient = $properties["fuu_to"]
$cc_recipient = $properties["fuu_cc"]
$subject = $properties["fuu_subject"]

Write-Log -Message "Tenant URL :: $($tenant_url)" -Level "INFO"
Write-Log -Message "Client ID :: $($client_id)" -Level "INFO"
Write-Log -Message "JAR Path :: $($jarPath)" -Level "INFO"
Write-Log -Message "File Path :: $($filePath)" -Level "INFO"
Write-Log -Message "Secret File Path :: $($secret)" -Level "INFO"
Write-Log -Message "To Recipient :: $($to_recipient)" -Level "INFO"
Write-Log -Message "CC Recipient :: $($cc_recipient)" -Level "INFO"
Write-Log -Message "Email Notification Subject :: $($subject)" -Level "INFO"

if (!$tenant_url -or !$client_id -or !$jarPath -or !$filePath -or !$secret) {
    Write-Log -Message "Mandatory parameters are missing" -Level "ERROR"
    Write-Log -Message "Please check Tenant URL, Client ID, Jar path and File path" -Level "ERROR"
    exit 1
}

if (!(Test-Path $jarPath)) {
    Write-Log -Message "Jar file path is not valid" -Level "ERROR"
    exit 1
}

if (!(Test-Path $filePath)) {
    Write-Log -Message "Feed file path is not valid" -Level "ERROR"
    exit 1
}

if (!(Test-Path $secret)) {
    Write-Log -Message "Secret file path is not valid" -Level "ERROR"
    exit 1
}

Write-Log -Message "Client Secret decryption --- start" -Level "INFO"

try {
    #Decrypt secret
    $AppSecretEncrypted = Get-Content $secret | ConvertTo-SecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AppSecretEncrypted)
    $client_Secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

} catch {

    $ErrorMessage = $_.Exception.Message 
  	$ErrorItem = $_.Exception.ItemName
  	Write-Log -Message "Error: Item = $ErrorItem -> Message = $ErrorMessage" -Level "ERROR"
}

Write-Log -Message "Client Secret decryption --- end" -Level "INFO"

try {
   
   #Run Aggregation command
   Write-Log -Message "Jar execution --- start" -Level "INFO"

   $aggResult = java -jar $jarPath --url $tenant_url --clientId $client_id --clientSecret $client_Secret --file $filePath -d

   Write-Log -Message "Jar execution --- end" -Level "INFO"

   if (!$to_recipient -or !$cc_recipient -or !$subject) {

       Write-Log -Message "Email Notification Parameters are missing" -Level "ERROR"

    } else {

       $body = "<!DOCTYPE html>
                <html>
                <head>
                    <title>Email Template</title>
                </head>
                <body>
                <p>Hi Team</p>
                <p>Please find below status on HR Source Aggregation using File Upload Utility</p>
                <br/>"

                foreach ($line in $aggResult) {

                    $body += "<p>$line</p>"

                }

                $body += "<br/><p>Thanks,<br/>IAM Team<br/>
                </body>
                </html>"


       try {

           $mail = "<path>\Send_Email_Graph.ps1"
           $mail_command = -join ($mail, " -mailBody '$body' -mailFrom '$mailFrom' -mailTo '$to_recipient' -mailCc '$cc_recipient' -mailSubject '$subject'")
           $sendEmail = Invoke-Expression "$mail_command"
           Write-Log -Message "Email Notification Sent" -Level "INFO"

       } catch {

           $ErrorMessage = $_.Exception.Message 
  	       $ErrorItem = $_.Exception.ItemName
           Write-Log -Message "Error in Sending Email" -Level "ERROR"
  	       Write-Log -Message "Error: Item = $ErrorItem -> Message = $ErrorMessage" -Level "ERROR"

       }
   }


} catch {

    $ErrorMessage = $_.Exception.Message 
  	$ErrorItem = $_.Exception.ItemName
  	Write-Log -Message "Error: Item = $ErrorItem -> Message = $ErrorMessage" -Level "ERROR"
}

Write-Log -Message "File Upload Utility ------ end" -Level "INFO"