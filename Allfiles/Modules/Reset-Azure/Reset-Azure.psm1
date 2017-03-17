Function Reset-Azure
# Remove virtual machines, virtual networks

{

    Start-Transcript -Path "D:\Logs\Reset-Azure.log" -IncludeInvocationHeader -Append -Force

    #We want to see any errors...
    $ErrorActionPreference='Continue'

    # Store the start time
    $starttime = Get-Date

    # Remove existing subscriptions and accounts from local PowerShell environment
    Write-Host "Removing cached Azure subscription references..."
    foreach ($sub in Get-AzureSubscription)
    {
        if ($sub.SubscriptionName)
        {
            Remove-AzureSubscription -SubscriptionName $sub.SubscriptionName -Force -WarningAction SilentlyContinue | Out-Null
        }
    }

    foreach ($acct in Get-AzureAccount)
    {
        Remove-AzureAccount $acct.Id -Force -WarningAction SilentlyContinue | Out-Null
    }

    # Sign into Azure
    Add-AzureAccount
    Login-AzureRmAccount

    # Select the target subscription
    Show-Subscription
    Show-SubscriptionARM

    $subName = (Get-AzureSubscription -Current).SubscriptionName

    Do {
        # Confirm with user before proceeding
        Write-Host -NoNewline "This script will remove all objects from your subscription $subName. Do you want to proceed? Y/N?: "  -ForegroundColor Magenta; $answer=read-host
        Switch ($answer)
        {
            Y {Write-Host "Deleting all objects..." -ForegroundColor Yellow}
            N {Write-Host "Terminating the script..."; Start-Sleep -Seconds 2; Return }
            Default {continue}
        }
    } While ($answer -notmatch "[YN]")

    if ((Get-AzureRmResourceGroup).Count -eq 0) {
        $endtime = Get-Date
        Write-Host Started at $starttime -ForegroundColor Magenta
        Write-Host Ended at $endtime -ForegroundColor Yellow
        Write-Host " "
        $elapsed = $endtime - $starttime
        if ($elapsed.Hours -ne 0){
            Write-Host Total elapsed time is $elapsed.Hours hours $elapsed.Minutes minutes -ForegroundColor Green
        } else {
            Write-Host Total elapsed time is $elapsed.Minutes minutes -ForegroundColor Green
        }        
        Write-Host " "
        Stop-Transcript
	Return
    }

    # Delete any VPN gateways
    # This will result in an error if there are no gateways, so temporarily change error action...
    $ErrorActionPreference = 'SilentlyContinue'
    $vnetDelay = $false
    foreach ($vnet in Get-AzureVNetSite) {
        if ($vnet) {
            Write-Host "Processing " $vnet.Name "virtual network ..."
            Remove-AzureVNetGateway -VNetName $vnet.Name
	    $vnetDelay = $true
        }
    }

    If ($vnetDelay) {
	Start-Sleep -Seconds 60 # Wait for previous operations to complete
    }

    # Delete all VMs and cloud services

    $vmDelay = $false
    foreach ($svc in Get-AzureService) {
        foreach ($vm in Get-AzureVM) {
            Stop-AzureVM -ServiceName $svc.ServiceName -Name $vm.Name -Force
            Remove-AzureVM -ServiceName $svc.ServiceName -Name $vm.Name -DeleteVHD
	    $vmDelay = $true
        }
        Remove-AzureService -ServiceName $svc.ServiceName -Force
    }

    If ($vmDelay) {
	Start-Sleep -Seconds 180 # Wait for previous operations to complete
    }    

    $ErrorActionPreference = 'Continue'

    # Delete everything else just in case ...
    Get-AzureDisk | Remove-AzureDisk -DeleteVHD
    Get-AzureStorageAccount | Remove-AzureStorageAccount

    # Delete all virtual networks, DNS servers etc.
    Remove-AzureVNetConfig

    # Delete all resource groups
    foreach ($rg in Get-AzureRMResourceGroup) {
        if ($rg) {
             Write-Host "Deleting " $rg.ResourceGroupName "resource group..."
             Remove-AzureRMResourceGroup -Name $rg.ResourceGroupName -Force
        }
    }

    # Display time taken for script to complete
    $endtime = Get-Date
    Write-Host Started at $starttime -ForegroundColor Magenta
    Write-Host Ended at $endtime -ForegroundColor Yellow
    Write-Host " "
    $elapsed = $endtime - $starttime
    If ($elapsed.Hours -ne 0){
        Write-Host Total elapsed time is $elapsed.Hours hours $elapsed.Minutes minutes -ForegroundColor Green
    } else {
        Write-Host Total elapsed time is $elapsed.Minutes minutes -ForegroundColor Green
    }
    Write-Host " "
    Stop-Transcript
}