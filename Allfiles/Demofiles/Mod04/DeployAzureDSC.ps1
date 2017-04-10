Login-AzureRmAccount

Show-SubscriptionARM

$resourceGroupName = '20533C0401-DemoRG'
$saPrefix = 'sa20533c04d'
$saType = 'Standard_LRS'
$maxValue = 999999

$randomNumber = Get-Random -Minimum 0 -Maximum $maxValue
$saName = $saPrefix + $randomNumber

$try = Get-AzureRmStorageAccountNameAvailability -Name $saName
If ($try1.NameAvailable -ne $True) {
	Do {
		$randomNumber = Get-Random -Minimum 0 -Maximum $maxValue
		$saName = $saPrefix + $randomnumber
		$try = Get-AzureRmStorageAccountNameAvailability -Name $saName
	}
	Until ($try.NameAvailable -eq $True)
}

$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName

$storageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $saName -Type $saType -Location $resourceGroup.Location
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccount.StorageAccountName)[0].Value

# we are using default container 
$containerName = 'windows-powershell-dsc'

$configurationName = 'IISInstall'
$configurationPath = ".\$configurationName.ps1"

$moduleURL = Publish-AzureRmVMDscConfiguration -ConfigurationPath $configurationPath -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccount.StorageAccountName -Force

$storageContext = New-AzureStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageAccountKey
$sasToken = New-AzureStorageContainerSASToken -Name $containerName -Context $storageContext -Permission r

$settingsHashTable = @{
"ModulesUrl" = "$moduleURL";
"ConfigurationFunction" = "$configurationName.ps1\$configurationName";
"SasToken" = "$sasToken"
}

$vmName1= 'Demo0401VM1'
$vmName2= 'Demo0401VM2'
$extensionName = 'DSC'
$extensionType = 'DSC'
$publisher = 'Microsoft.Powershell'
$typeHandlerVersion = '2.1'

Set-AzureRmVMExtension  -ResourceGroupName $resourceGroupName -VMName $vmName1 -Location $storageAccount.Location `
-Name $extensionName -Publisher $publisher -ExtensionType $extensionType -TypeHandlerVersion $typeHandlerVersion `
-Settings $settingsHashTable

Set-AzureRmVMExtension  -ResourceGroupName $resourceGroupName -VMName $vmName2 -Location $storageAccount.location `
-Name $extensionName -Publisher $publisher -ExtensionType $extensionType -TypeHandlerVersion $typeHandlerVersion `
-Settings $settingsHashTable
