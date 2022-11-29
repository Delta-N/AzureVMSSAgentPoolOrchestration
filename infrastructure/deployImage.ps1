param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$ImageName,
    [Parameter(Mandatory)][string]$StorageAccountName,
    [Parameter(Mandatory)][string]$HostingPlanName,
    [Parameter(Mandatory)][string]$ApplicationInsightsName,
    [Parameter(Mandatory)][string]$FunctionNamePrefix
)

$ErrorActionPreference = "Stop"

Write-Host "Getting AZSubscription..."
$Subscription = Get-AzSubscription
Write-Host "Connected to Subscription '$($Subscription.Name)'"

Write-Host "Deploying Scaling Function for $ImageName"
$Parameters = @{
    Name                          = "Deploy_Orchestration_Function"
    TemplateFile                  = "$PSScriptRoot\deployFunction.bicep"
    resourceGroupName             = $ResourceGroupName
    imageName                     = $ImageName
    functionNamePrefix            = $FunctionNamePrefix
    storageAccountName            = $StorageAccountName
    hostingPlanName               = $HostingPlanName
    applicationInsightsName       = $ApplicationInsightsName
    Verbose                       = $True
}

New-AzResourceGroupDeployment @Parameters
