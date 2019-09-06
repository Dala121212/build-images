Function Connect-AppVeyorToHyperV {
    <#
    .SYNOPSIS
        Command to enable Hyper-V builds. Works with both hosted AppVeyor and AppVeyor Server.

    .DESCRIPTION
        You can connect your AppVeyor account (on both hosted AppVeyor and on-premise AppVeyor Server) to Hyper-V host for AppVeyor to instantiate build VMs on it.

    .PARAMETER AppVeyorUrl
        AppVeyor URL. For hosted AppVeyor it is https://ci.appveyor.com. For Appveyor Server users it is URL of on-premise AppVeyor Server installation

    .PARAMETER ApiToken
        API key for specific account (not 'All accounts'). Hosted AppVeyor users can find it at https://ci.appveyor.com/api-keys. Appveyor Server users can find it at <appveyor_server_url>/api-keys.

    .PARAMETER ImageOs
        Operating system of build VM image. Valid values: 'Windows', 'Linux'. Default value is 'Windows'.

    .PARAMETER ImageName
        Description to be passed to Packer and name to be used for AppVeyor image.  Default value generated is based on the value of 'ImageOs' parameter.

    .PARAMETER ImageTemplate
        If you are familiar with the Hashicorp Packer, you can replace template used by this command with another one. Default value is '.\minimal-windows-server.json'.

        .EXAMPLE
        Connect-AppVeyorToHyperV
        Let command collect all required information

        .EXAMPLE
        Connect-AppVeyorToHyperV -ApiToken XXXXXXXXXXXXXXXXXXXXX -AppVeyorUrl "https://ci.appveyor.com"
        Run command with all required parameters so command will ask no questions. It will create build VM image and configure Hyper-V build cloud in AppVeyor.
    #>

    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory=$true,HelpMessage="AppVeyor URL`nFor hosted AppVeyor it is https://ci.appveyor.com`nFor Appveyor Server users it is URL of on-premise AppVeyor Server installation")]
      [string]$AppVeyorUrl,

      [Parameter(Mandatory=$true,HelpMessage="API key for specific account (not 'All accounts')`nHosted AppVeyor users can find it at https://ci.appveyor.com/api-keys`nAppveyor Server users can find it at <appveyor_server_url>/api-keys")]
      [string]$ApiToken,

      [Parameter(Mandatory=$false)]
      [ValidateSet('Windows','Linux')]
      [string]$ImageOs = "Windows",

      [Parameter(Mandatory=$false)]
      [string]$ImageName,

      [Parameter(Mandatory=$false)]
      [string]$ImageTemplate
    )

    function ExitScript {
        # some cleanup?
        break all
    }

    $ErrorActionPreference = "Stop"

    $StopWatch = New-Object System.Diagnostics.Stopwatch
    $StopWatch.Start()

    #Sanitize input
    $AppVeyorUrl = $AppVeyorUrl.TrimEnd("/")

    #Validate input
    if ($ApiToken -like "v2.*") {
        Write-Warning "Please select the API Key for specific account (not 'All Accounts') at '$($AppVeyorUrl)/api-keys'"
        ExitScript
    }

    try {
        $responce = Invoke-WebRequest -Uri $AppVeyorUrl -ErrorAction SilentlyContinue
        if ($responce.StatusCode -ne 200) {
            Write-warning "AppVeyor URL '$($AppVeyorUrl)' responded with code $($responce.StatusCode)"
            ExitScript
        }
    }
    catch {
        Write-warning "Unable to connect to AppVeyor URL '$($AppVeyorUrl)'. Error: $($error[0].Exception.Message)"
        ExitScript
    }

    $headers = @{
      "Authorization" = "Bearer $ApiToken"
      "Content-type" = "application/json"
    }
    try {
        Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/projects" -Headers $headers -Method Get | Out-Null
    }
    catch {
        Write-warning "Unable to call AppVeyor REST API, please verify 'ApiToken' and ensure '-AppVeyorUrl' parameter is set if you are using on-premise AppVeyor Server."
        ExitScript
    }

    if ($AppVeyorUrl -eq "https://ci.appveyor.com") {
          try {
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds" -Headers $headers -Method Get | Out-Null
        }
        catch {
            Write-warning "Please contact support@appveyor.com and request enabling of 'Private build clouds' feature."
            ExitScript
        }
    }

    try {
        
        Write-Host "Connecting to Hyper-V...done!"
    }

    catch {
        Write-Warning "Command exited with error: $($_.Exception)"
        ExitScript
    }
}



