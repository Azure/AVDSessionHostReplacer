function send-SHRDrainNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $sessionHostName,

        [Parameter()]
        [string] $HostPoolName = (Get-FunctionConfig _HostPoolName),

        [parameter()]
        [string] $ResourceGroupName = (Get-FunctionConfig _HostPoolResourceGroupName),

        [Parameter()]
        [int] $DrainGracePeriodHours = (Get-FunctionConfig _DrainGracePeriodHours),

        [Parameter()]
        [string] $messageTitle = "Automatic Session Host Maintenance",

        [Parameter()]
        [string] $message = "Your session host {0} is being replaced. Please save your work and log off. You will be disconnected in {1} hours."
    )
    # Get users on the session host
    $sessions = Get-AzWvdUserSession -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -SessionHostName $sessionHostName
    foreach ($session in $sessions){
        # Send message to user
        $sessionId = $session.Name -replace '.+\/.+\/(.+)', '$1'
        $messageBody = $message -f $sessionHostName, $DrainGracePeriodHours
        Write-PSFMessage -Level Host -Message 'Sending message to user {0} on session host {1}.' -StringValues $session.UserPrincipalName, $sessionHostName
        Send-AzWvdUserSessionMessage -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -SessionHostName $sessionHostName -UserSessionId $sessionId -MessageTitle $messageTitle -MessageBody $messageBody
    }
}