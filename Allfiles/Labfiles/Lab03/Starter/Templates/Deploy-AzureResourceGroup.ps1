$deploymentName	= "WebTierVM1-Deployment"
$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$templateFile = Join-Path -Path $rootPath -ChildPath 'Labfiles\Lab03\Starter\Templates\azuredeploywebvm.json'
$rgName	= "20533D0301-LabRG"

New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $rgName -TemplateFile $templateFile
