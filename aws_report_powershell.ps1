#
# AWS Report
#
# Requires AWS plugin: https://aws.amazon.com/powershell/
# Set-AWSCredentials -AccessKey <access key> -SecretKey <secret key> -Storeas <profile name>
# Full instructions found http://i-script-stuff.electric-horizons.com/?p=43&preview=true
#
#

#Just a quick check for powershell 3.0 and older:
if($PSVersionTable.PSVersion.Major -ge 4) {
Import-Module AWSPowerShell
} else {
Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"
}

#profiles to check
$profile_list = ("Example_1")


#Path configs
$website_path = "C:\inetpub\awsreport.html"
$website_tmp_path = ".\awsreport.tmp"
$csv_tmp_path = ".\awscsvreport.tmp"
$csv_path = "C:\inetpub\awsreport.csv"

echo "<html>
	  <head>
	  <title>AWS Report</title>
	  </head>
	  <body>
	<style style=""text/css"">
  	.hoverTable{
		width:100%; 
		border-collapse:collapse; 
	}
	.hoverTable th {
		padding:8px; border:#4e95f4 1px solid;background-color: #B4CDCD
	}
	
	}
	.hoverTable td{ 
		padding:7px; border:#4e95f4 1px solid;
	}
	/* Define the default color for all the table rows */
	.hoverTable tr{
		background: #b8d1f3;
	}
	/* Define the hover highlight color for the table row */
    .hoverTable tr:hover {
          background-color: #ffff99;
    }
</style>

<table class=""hoverTable"">" > $website_tmp_path
echo """Environment"",""Region"",""Instance Name"",""Instance ID"",""Instance Type"",""Powered State"",""Private IP Address"",""Public IP Address"", ""Security Groups""" > $csv_tmp_path

foreach($profile in $profile_list) {
echo "<tr><th>Environment</th><th>Region</th><th>Instance Name</th><th>Instance ID</th><th>Instance Type</th><th>Powered State</th><th>Private Ip Address</th><th>Public Ip Address</th><th>Security Groups</th></tr>" >> $website_tmp_path
Set-AWSCredentials -ProfileName $profile
$region_list = Get-AWSRegion | select -expandproperty Region

	foreach($region in $region_list) {
	$Instance_list = Get-EC2Instance -region $region |select -expandproperty instances

	$VPC_list = Get-EC2Vpc -Region $region
		foreach ($VPC in $VPC_list) {
		$Instance_list | Where-Object {$_.VpcId -eq $VPC.VpcId} | foreach-object {
            $Instance_name = ($_.Tags | Where-Object {$_.Key -eq 'Name'}).Value
            $Instance_id = $_.InstanceId
            $InstanceType = $_.InstanceType
			$Private_ip = $_.PrivateIpAddress
            $Public_ip = $_.PublicIpAddress
			$Power_State = $_.State.Name
            $SecurityGroups = $_.SecurityGroups.GroupName
			echo "$Profile,$Region,$Instance_name,$Instance_id,$InstanceType,$Power_State,$Private_ip,$Public_ip,$SecurityGroups"
			echo """$Profile"",""$Region"",""$Instance_name"",""$Instance_id"",""$InstanceType"",""$Power_State"",""$Private_ip"",""$Public_ip"",""$SecurityGroups""" >> $csv_tmp_path
			echo "<tr><td>$Profile</td><td>$Region</td><td>$Instance_name</td><td>$Instance_id</td><td>$InstanceType</td><td>$Power_State</td><td>$Private_ip</td><td>$Public_ip</td><td>$SecurityGroups</td></tr>" >> $website_tmp_path
			}
		}
	}
}
echo "</table></body></html>" >> $website_tmp_path
move-item $website_tmp_path $website_path -Force
move-item $csv_tmp_path $csv_path -Force