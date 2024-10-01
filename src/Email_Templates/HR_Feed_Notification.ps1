
param (
    [Parameter(Mandatory=$true)]
    [string]$joinerList,
    [Parameter(Mandatory=$true)]
    [string]$moverList,
    [Parameter(Mandatory=$true)]
    [string]$leaverList

)

function Get-Body {

$joinerList1 = $joinerList -split ','
$moverList1 = $moverList -split ','
$leaverList1 = $leaverList -split ','

$body = "<!DOCTYPE html>
<html>
<head>
    <title>Email Template</title>
	<style>
        table {
            border-collapse: collapse;
        }
        th, td {
            border: 1px solid black;
            padding: 8px;
        }
		thead {
            background-color: #FF671F;
        }
    </style>
</head>
<body>
    <p>Dear HR Team,</p>
    <p>We have received feed for today, please find below analysis</p>
	
    <p>Below are the users that are newly added to the feed</p>

    <table>
        <thead>
            <tr>
                <th>Employee ID</th>
            </tr>
        </thead>
        <tbody>"

foreach ($joiner in $joinerList1) {

    $body += "<tr>
                <td>$joiner</td>
            </tr>"

}

$body += "</tbody>
    </table>

    <p>Below are the users that are removed from the feed</p>

    <table>
        <thead>
            <tr>
                <th>Employee ID</th>
            </tr>
        </thead>
        <tbody>"

foreach ($leaver in $leaverList1) {

    $body += "<tr>
                <td>$leaver</td>
            </tr>"
}

$body += "</tbody>
    </table>
    
    <p>Below are the users whose data modified</p>

    <table>
        <thead>
            <tr>
                <th>Employee ID</th>
                <th>Attribute Name</th>
                <th>New Data</th>
                <th>Old Data</th>
            </tr>
        </thead>
        <tbody>"

foreach ($mover in $moverList1) {
    
    $tmp = @()
    $tmp = $mover.Split(":")

    $empNum = $null
    $attrName = $null
    $curData = $null
    $newData = $null

    $empNum = $tmp[0]
    $attrName = $tmp[1]
    $curData = $tmp[2]
    $newData = $tmp[3]

    $body += "<tr>
                <td>$empNum</td>
                <td>$attrName</td>
                <td>$curData</td>
                <td>$newData</td>
            </tr>"

}
            
$body += "</tbody>
    </table>
	
    <p>Please validate all the changes and send us the updated feed file within the next [X] hours of receiving this email if any changes are necessary.</p>

    <p><strong>Any mistakes during processing could result in employees losing access.</strong></p>

    <br/>

<p>Thanks<br/>
IAM Team</p>

</body>
</html>"


return $body

}

Get-Body