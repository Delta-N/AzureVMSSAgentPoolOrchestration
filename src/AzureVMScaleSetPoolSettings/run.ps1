param($Timer)

Function Set-ScaleSet {
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "Id of the target scale set")][ValidateNotNullOrEmpty()] [String]$poolId,
        [Parameter(Mandatory = $true, HelpMessage = "Desired Idle Count")][ValidateNotNullOrEmpty()][int]$desiredIdle,
        [Parameter(Mandatory = $true, HelpMessage = "Maximum number of instances" )][ValidateNotNullOrEmpty()][int]$MaxCapacity,
        [Parameter(Mandatory = $true, HelpMessage = "Recycle instances after each job")][ValidateNotNullOrEmpty()][bool]$recycleAfterEachUse,
        [Parameter(Mandatory = $true, HelpMessage = "Time to live in minutes")][ValidateNotNullOrEmpty()][int]$timeToLiveMinutes,
        [Parameter(Mandatory = $true, HelpMessage = "Azure DevOps organisation name")][ValidateNotNullOrEmpty()] [String]$azureDevOpsOrganizationName,
        [Parameter(Mandatory = $true, HelpMessage = "Azure DevOPs PAT")][ValidateNotNullOrEmpty()][String]$azureDevOpsPAT
    )
    Begin {
    }
    Process {
        If ($PSCmdlet.ShouldProcess("Update scaleset")) {

            #https://learn.microsoft.com/en-us/rest/api/azure/devops/distributedtask/elasticpools/update?view=azure-devops-rest-7.1   
            $body = @{
                "recycleAfterEachUse" = $recycleAfterEachUse
                "maxCapacity"         = $MaxCapacity
                "desiredIdle"         = $desiredIdle
                "timeToLiveMinutes"   = $timeToLiveMinutes
                "maxSavedNodeCount"   = 0
                "agentInteractiveUI"  = "false"
            }

            Write-Debug -Message "body: $($body)" -Debug

            $url = "https://dev.azure.com/$azureDevOpsOrganizationName/_apis/distributedtask/elasticpools/" + $poolId + "?api-version=7.1-preview.1"

            Write-Debug -Message "Set Elastic Pools Url: $($url)" -Debug
            Write-Debug -Message "setElasticPoolsUri: $($url)" -Debug
            Write-Debug -Message "Set Scale Set Response for: $poolId" -Verbose
            
            Try {
                $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($azureDevOpsPAT)"))
                $null = Invoke-RestMethod -Uri $url -Method Patch -Body ($body | ConvertTo-Json) -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $token) }
            }
            Catch {
                $message = $_
                Throw "Cannot set Elastic Pool settings from Azure DevOps. Error is: $($message)"
            }
            Write-Information -InformationAction Continue -MessageData "Updated pool $poolId; settings to: MaxCapacity: $($MaxCapacity) / desiredIdle: $($desiredIdle) /  recycleAfterEachUse: $($recycleAfterEachUse) / timeToLiveMinutes: $timeToLiveMinutes"
        }
    }
    End {

    }
}   

#Needed for logging
$ErrorActionPreference = "Stop"
$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'

If ($Timer.IsPastDue) {
    Write-Information "PowerShell timer is running late!"
}

$azureDevOpsOrganizationName = $env:AzureDevOpsOrganizationName
$azureDevOpsPAT = $env:AzureDevOpsPAT
$azureVMScaleSets = $env:AzureVMScaleSets
$recycleAfterEachUse = $env:RecycleAfterEachUse
$timeToLiveMinutes = $env:TimeToLiveMinutes

$businessHoursBegin = $env:BusinessHoursBegin
$businessHoursEnd = $env:BusinessHoursEnd
$businessHoursMaxCapacity = $env:BusinessHoursMaxCapacity
$businessHoursIdle = $env:BusinessHoursIdle
$outsideBusinessHoursMaxCapacity = $env:OutsideBusinessHoursMaxCapacity
$outsideBusinessHoursIdle = $env:OutsideBusinessHoursIdle
$weekendMaxCapacity = $env:weekendMaxCapacity
$weekendIdle = $env:weekendIdle

Try {
    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($azureDevOpsPAT)"))
    $url = "https://dev.azure.com/$azureDevOpsOrganizationName/_apis/distributedtask/elasticpools?api-version=7.1-preview.1"
    
    Write-Debug -Message "Get Elastic Pools Url: $($url)" -Debug

    $elasticPoolResponse = (Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $token) }).value

    If ($elasticPoolResponse) {
        #West Europe timezone
        $currentDate = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((get-date), "W. Europe Standard Time")
        Write-Information -InformationAction Continue -MessageData "Evaluation date/time is: $($currentDate.DayOfWeek), Time is: $($currentDate.Hour):$($currentDate.Minute)"
       
        foreach ($item in $elasticPoolResponse) {
            $scalesetName = ($item.azureId).split("/")[8]
            $poolID = $item.poolid

            If ($azureVMScaleSets -match $scalesetName) {
                Write-Information -InformationAction Continue -MessageData "Virtual Machine Scale Set '$scalesetName' is managed by this Azure Function."

                If (($currentDate.DayOfWeek -eq "Saturday") -or ($currentDate.DayOfWeek -eq "Sunday") ) {
                    Write-Information -InformationAction Continue -MessageData "It is weekend."
                    Set-ScaleSet -poolId $poolID -desiredIdle $weekendIdle -azureDevOpsPAT $azureDevOpsPAT  -maxCapacity $weekendMaxCapacity -recycleAfterEachUse $RecycleAfterEachUse -azureDevOpsOrganizationName $azureDevOpsOrganizationName -timeToLiveMinutes $timeToLiveMinutes
                }    
                ElseIf ($currentDate.Hour -lt $businessHoursBegin ) {
                    Write-Information -InformationAction Continue -MessageData "It is a weekday between $($businessHoursEnd):00 and $($businessHoursBegin):00; that means outside business hours."
                    Set-ScaleSet -poolId $poolID -desiredIdle $outsideBusinessHoursIdle -azureDevOpsPAT $azureDevOpsPAT -maxCapacity $outsideBusinessHoursMaxCapacity -recycleAfterEachUse $recycleAfterEachUse -azureDevOpsOrganizationName $azureDevOpsOrganizationName -timeToLiveMinutes $timeToLiveMinutes
                }
                ElseIf ($currentDate.Hour -gt $businessHoursEnd ) {
                    Write-Information -InformationAction Continue -MessageData "It is a weekday between $($businessHoursEnd):00 and $($businessHoursBegin):00; that means outside business hours."
                    Set-ScaleSet -poolId $poolID -desiredIdle $outsideBusinessHoursIdle -azureDevOpsPAT $azureDevOpsPAT -maxCapacity $outsideBusinessHoursMaxCapacity -recycleAfterEachUse $recycleAfterEachUse -azureDevOpsOrganizationName $azureDevOpsOrganizationName -timeToLiveMinutes $timeToLiveMinutes
                }  
                Else {
                    Write-Information -InformationAction Continue -MessageData "It is a weekday between $($businessHoursBegin):00 and $($businessHoursEnd):00; that means business hours."
                    Set-ScaleSet -poolId $poolID -desiredIdle $businessHoursIdle -azureDevOpsPAT $azureDevOpsPAT -maxCapacity $businessHoursMaxCapacity -recycleAfterEachUse $recycleAfterEachUse -azureDevOpsOrganizationName $azureDevOpsOrganizationName -timeToLiveMinutes $timeToLiveMinutes
                }
            }  
        }
    }
    Else {
        Throw "Cannot find any Elastic Pools in Azure DevOps."
    }
}
Catch {
    $message = $_
    Write-Error -Message "$($message)"
}
