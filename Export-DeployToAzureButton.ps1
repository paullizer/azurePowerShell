
function Export-DeployToAzureButton {

    Param(

        [Parameter(Mandatory=$true)]
        $deployJsonUrl,
        [Parameter(Mandatory=$false)]
        $formJsonUrl,
        [Parameter(Mandatory=$false)]
        [switch]$deployToAzureGovernment
    
        )

    $deployJsonEscapeDataString = [uri]::EscapeDataString($deployJsonUrl)
    
    if($formJsonUrl){
        $formJsonEscapeDataString = [uri]::EscapeDataString($formJsonUrl)
        $portalButtonUrl = "https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/"
        $formUrl = "/uiFormDefinitionUri/"

        if ($deployToAzureGovernment){
            $portalButtonUrl = $portalButtonUrl.Replace(".com",".us")
        }

        $deployToAzureUri = $portalButtonUrl + $deployJsonEscapeDataString + $formUrl + $formJsonEscapeDataString
    }
    else {
        $portalButtonUrl = "https://portal.azure.com/#create/Microsoft.Template/uri/"

        if ($deployToAzureGovernment){
            $portalButtonUrl = $portalButtonUrl.Replace(".com",".us")
        }

        $deployToAzureUri = $portalButtonUrl + $deployJsonEscapeDataString
    }
    
    return $deployToAzureUri
}

