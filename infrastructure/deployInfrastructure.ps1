param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$StorageAccountName,
    [Parameter(Mandatory)][string]$HostingPlanName,
    [Parameter(Mandatory)][string]$ApplicationInsightsName,
    [Parameter(Mandatory)][string]$ActionGroupName,
    [Parameter(Mandatory)][string]$AlertNotificationEmailAddress
)

$ErrorActionPreference = "Stop"

Write-Host "Getting AZSubscription..."
$Subscription = Get-AzSubscription
Write-Host "Connected to Subscription '$($Subscription.Name)'"

Write-Host "Deploying Resource Group"
$Parameters = @{
    Name              = "Deploy_ResourceGroup"
    TemplateFile      = "$PSScriptRoot\..\..\Bicep\resourceGroup.bicep"
    location          = "West Europe"
    resourceGroupName = $ResourceGroupName
}

$null = New-AzSubscriptionDeployment @Parameters

Write-Host "Deploying Function Infrastructure"
$Parameters = @{
    Name                          = "Deploy_Orchestration_Infrastructure"
    TemplateFile                  = "$PSScriptRoot\infrastructure.bicep"
    resourceGroupName             = $ResourceGroupName
    storageAccountName            = $StorageAccountName
    hostingPlanName               = $HostingPlanName
    applicationInsightsName       = $ApplicationInsightsName
    actionGroupName               = $ActionGroupName
    alertNotificationEmailAddress = $AlertNotificationEmailAddress
    Verbose                       = $True
}

New-AzResourceGroupDeployment @Parameters
