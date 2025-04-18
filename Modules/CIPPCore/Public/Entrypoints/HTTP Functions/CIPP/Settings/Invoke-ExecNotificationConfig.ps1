using namespace System.Net

Function Invoke-ExecNotificationConfig {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        CIPP.AppSettings.ReadWrite
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    Write-LogMessage -headers $Headers -API $APIName -message 'Accessed this API' -Sev 'Debug'



    $sev = ([pscustomobject]$Request.body.Severity).value -join (',')
    $results = try {
        $Table = Get-CIPPTable -TableName SchedulerConfig
        $SchedulerConfig = @{
            'tenant'            = 'Any'
            'tenantid'          = 'TenantId'
            'type'              = 'CIPPNotifications'
            'schedule'          = 'Every 15 minutes'
            'Severity'          = [string]$sev
            'email'             = "$($Request.Body.email)"
            'webhook'           = "$($Request.Body.webhook)"
            'onePerTenant'      = [boolean]$Request.Body.onePerTenant
            'sendtoIntegration' = [boolean]$Request.Body.sendtoIntegration
            'includeTenantId'   = [boolean]$Request.Body.includeTenantId
            'PartitionKey'      = 'CippNotifications'
            'RowKey'            = 'CippNotifications'
        }
        foreach ($logvalue in [pscustomobject]$Request.body.logsToInclude) {
            $SchedulerConfig[([pscustomobject]$logvalue.value)] = $true
        }

        Add-CIPPAzDataTableEntity @Table -Entity $SchedulerConfig -Force | Out-Null
        'Successfully set the configuration'
    } catch {
        "Failed to set configuration: $($_.Exception.message)"
    }


    $body = [pscustomobject]@{'Results' = $Results }

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $body
        })

}
