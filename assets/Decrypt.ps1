$AppSecretEncrypted = Get-Content "<encrypted secret file path>" | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AppSecretEncrypted)
$AppSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$AppSecret