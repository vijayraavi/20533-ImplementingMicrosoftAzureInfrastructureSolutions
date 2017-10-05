$deploymentName	= "WebTierVM1-Deployment"
$templateFile = 'E:\Labfiles\Lab03\Starter\Templates\azuredeploywebvm.json'
$rgName	= "20533D0301-LabRG"

New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $rgName -TemplateFile $templateFile
