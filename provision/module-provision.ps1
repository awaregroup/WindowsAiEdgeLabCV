az login
az account set -s "MS IoT Labs - Windows IoT"
$iotHubs = (ConvertFrom-Json([string](az iot hub list --query "[].name")))

$devices = $iotHubs | %{ 
		Write-Host $_;
		 $iotHub = $_;
		 $deviceIds = (ConvertFrom-Json([string](az iot hub device-identity list --hub-name $_))).deviceId;
		 if ($deviceIds -ne $null) { 
			 $deviceIds | % {  
			 Write-Host $iotHub $_
				 @{  
				    iotHub = $iotHub; 
				    deviceId = $_;
				  } 
			  } 
			}
	}

$devices | % { az iot edge set-modules --device-id $_.deviceId --hub-name $_.iotHub --content deployment.win-x64.json }
$devices | % { (ConvertFrom-Json([string](az iot hub module-identity list --device-id $_.deviceId --hub-name $_.iotHub))) | Select-Object deviceId, moduleId, connectionState } 

