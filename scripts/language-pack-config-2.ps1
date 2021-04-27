param(
    [Parameter(Mandatory=$true)]
    [String]
    $Language,

    [Parameter(Mandatory=$true)]
    [String]
    $Platform
)

Write-Host("Configure Japanese localization settings Step 2 $Language $Platform")

switch ( $Platform) {
    "win2016" {
        switch ( $Language ) {
            "jpn" {
                $LangCode = 'ja-JP'
                $Timezone = "Tokyo Standard Time"

                Write-Host( "Set the location to Japan")
                # Is this appropriate? This image may be started in any region of the world. What does it mean to be 'in Japan' when you may be running anywhere?
                Set-WinHomeLocation -GeoId 0x7A
            }
        }
    }
    "win2019" {
        switch ( $Language ) {
            "jpn" {
                $LangCode = 'ja-JP'
                $Timezone = "Tokyo Standard Time"

                Write-Host( "Set the location to Japan")
                # Is this appropriate? This image may be started in any region of the world. What does it mean to be 'in Japan' when you may be running anywhere?
                Set-WinHomeLocation -GeoId 0x7A
            }
        }
    }
}

Write-Host( "Make the time / date format the same as the Windows language")
Set-WinCultureFromLanguageListOptOut -OptOut $False

Write-Host( "Overwrite the UI language with Japanese")
Set-WinUILanguageOverride -Language $LangCode

Write-Host( "Set the system locale to Japan")
Set-WinSystemLocale -SystemLocale $LangCode

Write-Host( "Set timezone to Tokyo time")
Set-TimeZone -Id $Timezone

Write-Host( "Make sysprep set the language & timezone correctly")

$filename = "$ENV:ProgramData\Amazon\EC2-Windows\Launch\Sysprep\Unattend.xml"
if ( Test-Path $filename) {
    Write-Host( "Presuming AWS image")
    $Doc = Get-Content $filename
    $Doc | % { $_.Replace("en-US", $LangCode) } | % { $_.Replace("UTC", $Timezone) } | Set-Content $filename
} else {
    # Write-Host( "Presuming Azure image")
    # $filename = "c:\lansa\scripts\AzureLanguageUnattend.xml"
    # mkdir "c:\lansa\sysprep" -ErrorAction SilentlyContinue
    # $Target = "c:\lansa\sysprep\AzureLanguageUnattend.xml"
    # $Doc = Get-Content $filename
    # $Doc | % { $_.Replace("en-US", $LangCode) } | % { $_.Replace("UTC", $Timezone) } | Set-Content $Target
}

Start-Sleep -Seconds 30
Restart-Computer -ErrorAction SilentlyContinue