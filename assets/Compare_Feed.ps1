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

# Import the CSV files
$oldFilepath = "<old feed file path>"
$newFilepath = "<new feed file path>"

$oldFile = Import-Csv -Path $oldFilepath
$newFile = Import-Csv -Path $newFilepath

$oldEmp = @()
$oldEmp += $oldFile.'emp_id'
#$oldEmp

$newEmp = @()
$newEmp += $newFile.'emp_id'
#$newEmp

$leaverList = @()
$leaverList += $oldEmp | Where-Object { $newEmp -notcontains $_ }

if (!($leaverList)) {
    $leaverList += "No Leavers"
}

$leaverList1 = $leaverList -join ','
#$leaverList1

$joinerList = @()
$joinerList += $newEmp | Where-Object { $oldEmp -notcontains $_ }

if (!($joinerList)) {
    $joinerList += "No Joiners"
}

$joinerList1 = $joinerList -join ','
#$joinerList1

$moverList = @()
$moverList += $newEmp | Where-Object { $oldEmp -contains $_ }
#$moverList

$oldlastNameTable = @{}
$newlastNameTable = @{}

$oldPosTable = @{}
$newPosTable = @{}

$oldEndDateTable = @{}
$newEndDateTable = @{}

$oldMgrTable = @{}
$newMgrTable = @{}

$oldStatusTable = @{}
$newStatusTable = @{}

$oldEmpTypeTable = @{}
$newEmpTypeTable = @{}

$oldDeptTable = @{}
$newDeptTable = @{}

foreach ($record in $oldFile) {
    $oldlastNameTable.Add($record.'emp_id', $record.'last_name')
    $oldPosTable.Add($record.'emp_id', $record.'position')
    $oldEndDateTable.Add($record.'emp_id', $record.'end_date')
    $oldMgrTable.Add($record.'emp_id', $record.'manager')
    $oldStatusTable.Add($record.'emp_id', $record.'employee_status')
    $oldEmpTypeTable.Add($record.'emp_id', $record.'employee_type')
    $oldDeptTable.Add($record.'emp_id', $record.'department')
}

foreach ($record2 in $newFile) {
    $newlastNameTable.Add($record2.'emp_id', $record2.'last_name')
    $newPosTable.Add($record2.'emp_id', $record2.'position')
    $newEndDateTable.Add($record2.'emp_id', $record2.'end_date')
    $newMgrTable.Add($record2.'emp_id', $record2.'manager')
    $newStatusTable.Add($record2.'emp_id', $record2.'employee_status')
    $newEmpTypeTable.Add($record2.'emp_id', $record2.'employee_type')
    $newDeptTable.Add($record2.'emp_id', $record2.'department')
}

$dataChangeList = @()

foreach ($emp in $moverList) {

    if ($newlastNameTable[$emp] -ne $oldlastNameTable[$emp]) {

        $dataChangeList += $emp + ":Last Name:" + $newlastNameTable[$emp] + ":" + $oldlastNameTable[$emp]

    } if ($newPosTable[$emp] -ne $oldPosTable[$emp]) {

        $dataChangeList += $emp + ":Position:" + $newPosTable[$emp] + ":" + $oldPosTable[$emp]

    } if ($newEndDateTable[$emp] -ne $oldEndDateTable[$emp]) {
        
        $dataChangeList += $emp +":End Date:" + $newEndDateTable[$emp] + ":" + $oldEndDateTable[$emp]
    
    } if ($newMgrTable[$emp] -ne $oldMgrTable[$emp]) {
        
        $dataChangeList += $emp + ":Manager:" + $newMgrTable[$emp] + ":" + $oldMgrTable[$emp]

    } if ($newStatusTable[$emp] -ne $oldStatusTable[$emp]) {
        
        $dataChangeList += $emp + ":Employee Status:" + $newStatusTable[$emp] + ":" + $oldStatusTable[$emp]

    } if ($newEmpTypeTable[$emp] -ne $oldEmpTypeTable[$emp]) {
        
        $dataChangeList += $emp + ":Employee Type:" + $newEmpTypeTable[$emp] + ":" + $oldEmpTypeTable[$emp]

    } if ($newDeptTable[$emp] -ne $oldDeptTable[$emp]) {
        
        $dataChangeList += $emp + ":Department:" + $newDeptTable[$emp] + ":" + $oldDeptTable[$emp]

    }
}

if (!($dataChangeList)) {
    
    $dataChangeList += "NA:NA:NA:NA"
}

#$dataChangeList
#break

$dataChangeList1 = $dataChangeList -join ','

$feed_template = "<path>\HR_Feed_Notification.ps1"
$feed_command = -join ($feed_template, " -joinerList '$joinerList1' -moverList '$dataChangeList1' -leaverList '$leaverList1'")
$mailBody = Invoke-Expression "$feed_command"
#$mailBody
#break

$properties = @{}

# Read the properties file
try {
    $lines = Get-Content -Path $propertiesFile -ErrorAction Stop
} catch {
    Write-Log -Message "Failed to read the properties file: $_" -Level "ERROR"
    exit 1
}


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


$mailFrom = $properties["from"]
$to_recipient = $properties["hrfc_to"]
$cc_recipient = $properties["hrfc_cc"]
$subject = $properties["hrfc_subject"]

$mail = "<path>\Send_Email_Graph.ps1"
$mail_command = -join ($mail, " -mailBody '$mailBody' -mailFrom '$mailFrom' -mailTo '$to_recipient' -mailCc '$cc_recipient' -mailSubject '$subject'")
$sendEmail = Invoke-Expression "$mail_command"