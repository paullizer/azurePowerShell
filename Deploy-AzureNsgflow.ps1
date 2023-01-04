# Step 1: Create or select a Log Analytics workspace
# Step 2: Create or select a Network Watcher per Region
# Step 3: Create or select a Storage Account per Region
# Step 3: Update $globalResources, $regionalResources
# Step 4: Copy and paste this code into the Azure PowerShell window in the Azure Portal OR locally if you have Az module installed

# Run against all subscriptions 
# Deploy-AzureNsgflow.ps1

# Run against a targeted subscription, must supply subscription name
# Deploy-AzureNsgflow.ps1 -targetSubscription "ENTER_SUBSCRIPTION_NAME"



$errorActionPreference = "Stop"
$WarningPreference = "SilentlyContinue"

Param(

        [Parameter(Mandatory=$false)]
        [string]$targetSubscription
        )

class GlobalResources {
    [string]$lawName
    [string]$lawResourceGroup;
}

class RegionalResources {
    [string]$region
    [string]$nwName
    [string]$nwResourceGroup
    [string]$saName
    [string]$saResourceGroup;
}

# YOU MUST UPDATE THESE VARIABLES WITH YOUR ORGANIZATION'S INFORMATION!!
$globalResources = @(
    [GlobalResources]@{
        lawName='ENTER_LAW_NAME_HERE';
        lawResourceGroup='ENTER_LAW_RESOURCE_GROUP_NAME_HERE'
    }
)

$regionalResources = @(
    # East US
    [RegionalResources]@{
        region='EastUS'; # IF YOU DONT HAVE EASTUS, REPLACE WITH YOUR REGION
        nwName='ENTER_NETWORK_WATCHER_NAME_HERE';
        nwResourceGroup='ENTER_NETWORK_WATCHER_RESOURCE_GROUP_NAME_HERE';
        saName='ENTER_STORAGE_ACCOUNT_NAME_HERE';
        saResourceGroup='ENTER_STORAGE_ACCOUNT_RESOURCE_GROUP_NAME_HERE'
    }
)



function Deploy-Nsgflow {

    try {
        Write-host "Collecting Log Analytics, Network Watcher, and Storage Account details."
        $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -Name $globalResources.lawName -ResourceGroupName $globalResources.lawResourceGroup
    }
    catch {
        Write-Host " Failed to collect Log Analytics workspace, please review variable values in script and correct. Exiting script"
        exit 0
    }

    foreach ($subscription in $allSubscriptions){
        Write-Host "Sub:" $subscription.Name
        Select-AzSubscription $subscription.Name | Out-Null 
        
        $allResourceGroups = Get-AzResourceGroup

        foreach ($resourceGroup in $allResourceGroups){
            Write-Host " RG:" $resourceGroup.ResourceGroupName
            $allVirtualNetworks = Get-AzVirtualNetwork -ResourceGroupName $resourceGroup.ResourceGroupName
            
            foreach ($virtualNetwork in $allVirtualNetworks){

                $locationMatch = $false

                foreach($region in $regionalResources){
                    if ($region.region.ToLower() -eq $virtualNetwork.Location){
                        $networkWatcher = Get-AzNetworkWatcher -Name $region.nwName -ResourceGroupName $region.nwResourceGroup
                        $storageAccount = Get-AzStorageAccount -Name $region.saName -ResourceGroupName $region.saResourceGroup
                        $locationMatch = $true
                        break
                    }
                }

                if ($locationMatch){
                    Write-Host "  VNET:" $virtualNetwork.Name

                    $nameNsg = "NSG-" + $virtualNetwork.Name
                    
                    Write-Host "   NSG:" $nameNsg

                    try {
                        $networkSecurityGroup = Get-AzNetworkSecurityGroup -Name $nameNsg -ResourceGroupName $resourceGroup.ResourceGroupName
                    }
                    catch {
                        Write-Host "    Creating NSG."
                        $networkSecurityGroup = New-AzNetworkSecurityGroup -Name $nameNsg -ResourceGroupName $resourceGroup.ResourceGroupName -Location $virtualNetwork.Location
                        
                    }
            
                    try {
                        Write-Host "    Configuring Diagnostic setting."
                        Set-AzDiagnosticSetting -ResourceId $networkSecurityGroup.Id -WorkspaceId $logAnalyticsWorkspace.ResourceId -Enabled $true | Out-Null
                    }
                    catch {
                        Write-Host "    Failed to configure Diagnostic setting."
                    }

                    try {
                        Write-Host "    Configuring Netflow."
                        Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $networkWatcher -TargetResourceId $networkSecurityGroup.Id -StorageAccountId $storageAccount.Id -EnableFlowLog $true -FormatType Json -FormatVersion 2 -EnableTrafficAnalytics -WorkspaceResourceId $logAnalyticsWorkspace.ResourceId -WorkspaceGUID $logAnalyticsWorkspace.CustomerId -WorkspaceLocation $logAnalyticsWorkspace.Location | Out-Null
                    }
                    catch {
                        Write-Host "   Failed to configure Netflow."
                    }

                    $allSubnets = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $virtualNetwork

                    foreach ($subnet in $allSubnets){
                        Write-Host "   Subnet:" $subnet.Name

                        Set-AzVirtualNetworkSubnetConfig -Name $subnet.Name -VirtualNetwork $virtualNetwork -NetworkSecurityGroup $networkSecurityGroup -AddressPrefix $subnet.AddressPrefix | Out-Null
                        
                        Write-Host "    Updating VNET"

                        try {
                            $virtualNetwork | Set-AzVirtualNetwork | Out-Null
                            Write-Host "    Successfully updated VNET"
                        }
                        catch {
                            Write-Host "    No update required, subnet managed by an Azure PaaS service."
                        }
                        
                        $virtualNetwork = Get-AzVirtualNetwork -Name $virtualNetwork.Name -ResourceGroupName $resourceGroup.ResourceGroupName
                    }
                }
                else {
                    Write-host "No Network Watcher found in" $virtualNetwork.Name " region. Create a Network Watcher in" $virtualNetwork.Location "and run again."
                }
            }
        }
    }
    
}

if ($targetSubscription){
    $allSubscriptions = Get-AzSubscription -SubscriptionName $targetSubscription
} else {
    $allSubscriptions = Get-AzSubscription 
}

Register-AzResourceProvider -ProviderNamespace Microsoft.Insights | Out-Null

Deploy-Nsgflow
