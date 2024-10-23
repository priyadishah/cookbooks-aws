<#
.SYNOPSIS

Install the remaining parts of the base LANSA image one Windows Updates has been applied.

.DESCRIPTION

These tasks must all occur after Windows Updates. If they can be applied earlier, they should be applied earlier

.EXAMPLE


#>

param (
    [Parameter(Mandatory=$true)]
    [string]
    $GitRepoPath,

    [Parameter(Mandatory=$true)]
    [string]
    $TempPath
    )

try
{
    $Cloud = (Get-ItemProperty -Path HKLM:\Software\LANSA  -Name 'Cloud').Cloud
    $Language = (Get-ItemProperty -Path HKLM:\Software\LANSA  -Name 'Language').Language

    Write-Host "$(Log-Date) Updating $Cloud instance, Language $Language"

    Write-Host "$(Log-Date) Synchronise clock"

    cmd /c "sc triggerinfo w32time start/networkon stop/networkoff" | Out-Default

    Write-Host "$(Log-Date) Ensure that Framework caching is completed"

    cmd /c "C:\Windows\Microsoft.NET\Framework\v4.0.30319\Ngen executequeueditems" | Out-Null
    cmd /c "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Ngen executequeueditems" | Out-Null

    if ( $Cloud -eq "AWS" ) {
        $LogsFound = $False
        Write-Host "$(Log-Date) Tidy Up EC2 Launch"
        $EC2LogPath = "$ENV:ProgramFiles\Amazon\Ec2ConfigService"
        if ( Test-Path $EC2LogPath ) {
            Write-Host "$(Log-Date) Configure EC2 Settings Win 2012?"
            Write-Host( "$(Log-Date) $EC2LogPath" )
            &"$Script:IncludeDir\Ec2ConfigSettings.ps1" "$TempPath" | Out-Default | Write-Host
            Remove-Item "$EC2LogPath\Logs\*.txt" -Force -Confirm:$false | Out-Default | Write-Host
            $LogsFound = $True
        }

        $EC2LogPath = "$ENV:ProgramData\Amazon\EC2-Windows\Launch\Log"
        if (Test-Path $EC2LogPath){
            Write-Host( "$(Log-Date) Newer EC2 Launch service Win 2016 & 2019?" )
            Write-Host( "$(Log-Date) $EC2LogPath" )
            Remove-Item "$EC2LogPath\*.*" -Force -Confirm:$false | Out-Default | Write-Host
            $LogsFound = $True
        }

        $EC2LogPath = "$ENV:ProgramData\Amazon\EC2Launch\Log"
        if (Test-Path $EC2LogPath){
            Write-Host( "$(Log-Date) Even Newer EC2 Launch service Win 2022?" )
            Write-Host( "$(Log-Date) $EC2LogPath" )
            Remove-Item "$EC2LogPath\*.*" -Force -Confirm:$false | Out-Default | Write-Host
            $LogsFound = $True
        }

        if ( -not $LogsFound ) {
            throw 'EC2 Launch log file location not found'
        }
    }

    Write-Host "$(Log-Date) Tidy up"

    if (Test-Path -Path $TempPath) {
        cmd /c rd /S/Q $TempPath | Out-Default | Write-Host
    }

    if ( $Cloud -eq "Azure " -and ($Language -ne 'ENG') ) {
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "ConfigureLanguage" -Value "powershell -executionpolicy Bypass -file $GitRepoPath\scripts\recover-language-pack.ps1" | Out-Default | Write-Host

        # $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy unrestricted -file $GitRepoPath\scripts\recover-language-pack.ps1"
        # $trigger1 = New-ScheduledTaskTrigger -AtStartup
        # Register-ScheduledTask -Action $action -Trigger $trigger1 -TaskName "Set $Language language settings" -RunLevel Highest -user System -TaskPath "\"
    }
}
catch
{
    $_
    $Global:LANSAEXITCODE = $LASTEXITCODE
    Write-RedOutput "Remote-Script LASTEXITCODE = $LASTEXITCODE" | Out-Default | Write-Host
    Write-RedOutput "install-lansa-post-winupdates.ps1 is the <No file> in the stack dump below" | Out-Default | Write-Host
    throw
}