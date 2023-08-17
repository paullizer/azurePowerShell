<#
    Ifyou get the following error
        GenericArguments[0], 'Microsoft.Azure.Management.Network.Models.SecurityRule', on 'T MaxInteger[T](System.Collections.Generic.IEnumerable`1[T])' violates the constraint of type 'T'.
    You must downgrade PowerShell or use non-PowerShell 7 shell
        https://learn.microsoft.com/en-us/answers/questions/1120276/azure-powershell-error-genericarguments(0)-microso

#>

# Update to use the subscription ID of the vWAN hub
$subscriptionId = "subscription_id"

# Update to use the original/primary hub, this hub will have all of its vnet connections removed
$primaryVirtualHubResourceGroupName = "RG-vWAN"
$primaryVirtualHubName = "hub-east"

# Update to use the backup hub, this hub will have all of the original hub's vnet connections added
$backupVirtualHubResourceGroupName = "RG-vWAN"
$backupVirtualHubName = "hub-west"

# Logs admin into the portal
Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId

# Collects a list of all the vnet connections
$originalVirtualHubVnetConnections = Get-AzVirtualHub -ResourceGroupName $primaryVirtualHubResourceGroupName -Name $primaryVirtualHubName | Get-AzVirtualHubVnetConnection

# Removes each vnet connection from primary hub
# This step can take a few minutes per connection to complete, if you look at the virtual network connections section in the vWAN portal you will see "Deleting" in the Conneciton Provisioning Status column
foreach ($vnetConnection in $originalVirtualHubVnetConnections) {
    $vnetConnection | Remove-AzVirtualHubVnetConnection -Force
}

# Adds each vnet connection to the backup hub
# This step can take 15 minutes to complete
foreach ($vnetConnection in $originalVirtualHubVnetConnections) {
    New-AzVirtualHubVnetConnection -Name $vnetConnection.Name -ResourceGroupName $backupVirtualHubResourceGroupName -VirtualHubName $backupVirtualHubName -RemoteVirtualNetworkId $vnetConnection.RemoteVirtualNetwork.Id 
}