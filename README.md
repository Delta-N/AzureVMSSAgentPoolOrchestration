[[TOC]]

## Auto adjust Azure virtual machine scale set pool settings

This Azure Function can auto adjust the settings of the Azure virtual machine scale set pool settings based on the business hours.
The idea is simpel:

- When inside business hours we want enough capacity to support our developers
- When outside business hours we want enough capacity to run nightly builds but not spend to much money on machines that are idle
- When in the weekend we want to save money to shutdown our agent pools

## Settings

The settings are stored in the 'configuration' of the function. The Configuration is passed to the function app by providing the settings during deployment (see the pipeline).

### Pat token

The PAT token for Azure DevOps needs to be configured in the pipeline with variablename `PAT`.
Only requires scope 'Agent Pool' with permissions 'Read & Manage'

### variables.yml

In the `variables.yml` file generic settings are stored regarding the names of the resources.

### <imageType>.yml

Per ImageName a `yml` file needs to be created to manage the settings. The VMSS name is concatenated from: $(vmssNamePrefix)${{ ImageName }}
Please note: The API call towards Azure DevOps do not need the Agent Pool name. Only the VMSS name is required, hence the vmssNamePrefix is required.

| Setting                  | Comment                                                                                                        |
| ------------------------ | -------------------------------------------------------------------------------------------------------------- |
| RecycleAfterEachUse      | Corresponds with the setting 'Automatically tear down virtual machines after every use'                        |
| TimeToLiveMinutes        | Corresponds with the setting 'Delay in minutes before deleting excess idle agents'                             |
| BusinessHoursBegin       | The hour in the morning when the business hours starts, for example 7 for 7:00 o'clock in the morning.         |
| BusinessHoursEnd         | The hour in the evening when the business hours ends, for example 19 for 19:00 o'clock in the evening.         |
| BusinessHoursMaxCapacity | Corresponds with the setting 'Maximum number of virtual machines in the scale set' within the business hours.  |
| BusinessHoursIdle        | Corresponds with the setting 'Number of agents to keep on standby' within the business hours.                  |
| BusinessHoursMaxCapacity | Corresponds with the setting 'Maximum number of virtual machines in the scale set' outside the business hours. |
| OutsideBusinessHoursIdle | Corresponds with the setting 'Number of agents to keep on standby' outside the business hours.                 |
| BusinessHoursMaxCapacity | Corresponds with the setting 'Maximum number of virtual machines in the scale set' in the weekend.             |
| WeekendIdle              | Corresponds with the setting 'Number of agents to keep on standby' in the weekend.                             |

## Adjust the update interval

Default the function runs every 15 minutes. This can be configured in the file `AzureVMScaleSetPoolSettings/function.json` / `bindings.schedule`
