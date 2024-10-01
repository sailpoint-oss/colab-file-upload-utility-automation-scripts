# Prompt the user for credentials
$credential = Get-Credential -Message "Enter your credentials"

# Convert the secure password to a secure string object
$secureString = $credential.Password | ConvertFrom-SecureString

# Save the secure string object to a file
$secureString | Out-File "<path>"
