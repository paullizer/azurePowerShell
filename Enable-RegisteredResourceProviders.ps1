
function Enable-RegisteredResourceProviders {
   
    $providerArray = @(
        "Microsoft.Sql",
        "Microsoft.Maintenance",
        "Microsoft.ContainerInstance",
        "Microsoft.OperationalInsights",
        "Microsoft.SecurityInsights",
        "Microsoft.OperationsManagement",
        "microsoft.insights",
        "Microsoft.ManagedIdentity",
        "Microsoft.PolicyInsights",
        "Microsoft.Security",
        "Microsoft.Management",
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Diagnostics",
        "Microsoft.RecoveryServices",
        "Microsoft.Compute",
        "Microsoft.Network",
        "Microsoft.Advisor",
        "Microsoft.ResourceHealth",
        "Microsoft.Automation",
        "Microsoft.AlertsManagement",
        "Microsoft.Logic",
        "Microsoft.Web",
        "Microsoft.DataFactory",
        "Microsoft.EventHub",
        "Microsoft.HybridCompute",
        "Microsoft.ContainerService",
        "Microsoft.Purview",
        "Microsoft.DesktopVirtualization",
        "Microsoft.HybridConnectivity",
        "Microsoft.Batch",
        "Microsoft.App",
        "Microsoft.Authorization",
        "Microsoft.Billing",
        "Microsoft.Consumption",
        "Microsoft.CostManagement",
        "Microsoft.MarketplaceOrdering",
        "Microsoft.ResourceGraph",
        "Microsoft.Resources"
    )

    $failures = @()
    $successes = @()

    Clear-Host

    try {
        
        Write-Host "Discovering Subscriptions."
        $subscriptions = Get-AzSubscription
        Write-Host ("`tSuccessfully discovered " + $subscriptions.count + " subscriptions.")
    }
    catch {
        Write-Host "`tFailed to collect subscriptions. This is a fatal error. Validate you have rights to one or more subscriptions. Exiting process."
        exit
    }

    Write-Host ("`nAdding " + $providerArray.count + " resource providers to your " + $subscriptions.count + " subscriptions.")

    foreach ($subscription in $subscriptions){
        try {
            Write-Host ("`nSetting subscription context to " + $subscription.Name)
            Set-AzContext -SubscriptionId $subscription.SubscriptionId |Out-Null
            Write-Host ("`t`tSuccessfully set subscription context")
        }
        catch {
            Write-Host "`t`tFailed to set subscription context. This is a fatal error. Validate you have rights to one or more subscriptions. Exiting process."
            exit
        }

        foreach ($provider in $providerArray){
            try {
                Write-Host ("`tRegistering resource provider " + $provider)
                Register-AzResourceProvider -ProviderNamespace $provider | Out-Null
                $successes += ($subscription.Name + "," + $provider)
                Write-Host ("`t`t Successfully registered provider.")
            }
            catch {
                Write-Host ("`t`t Failed to registered provider.")
                $failures += ($subscription.Name + "," + $provider)
            }
        }
    }

    if ($successes.count -gt 0){
        Write-Host ("`nRegistration Successes: " + $successes.count)
    }

    if ($failures.count -gt 0){
        Write-Host ("Registration Failures: " + $failures.count)
        Write-Host ("`nFailures:")
        Write-Host $failures
    }
}