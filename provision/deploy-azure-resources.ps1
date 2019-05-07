az account set -s "MS IoT Labs - Windows IoT"
1..30 | % {
            $userId = "{0:00}" -f $_
            $userObjectId = (Get-AzureADUser -ObjectId "lab.user$($userId)@msiotlabs.com").ObjectId
            $resultOne = New-AzureRmResourceGroupDeployment -ResourceGroupName "msiotlabs-user$userId-winiot" -Name "msiotlabs-$userId-winiot" -TemplateFile ./WindowsAiEdgeLabCV.template.json -primaryRegion "westus" -labUserNumberObjectId $userObjectId;
            if($resultOne -eq $null) {
                New-AzureRmResourceGroupDeployment -ResourceGroupName "msiotlabs-user$userId-winiot" -Name "msiotlabs-$userId-winiot" -TemplateFile ./WindowsAiEdgeLabCV.template.json -primaryRegion "westus2" -labUserNumberObjectId $userObjectId;
            }
            $iotHubs = (ConvertFrom-Json ([string](az iot hub list --resource-group "msiotlabs-user$userId-winiot" --query "[].name")))
            $iotHubs | % { az iot hub consumer-group create --name "timeseriesinsights" --hub-name $_  }
}


