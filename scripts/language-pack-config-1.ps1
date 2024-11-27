param(
    [Parameter(Mandatory=$true)]
    [String]
    $Language,

    [Parameter(Mandatory=$true)]
    [String]
    $Platform
)
Write-Host("Configure Japanese localization settings Step 1 $Language $Platform")
switch ( $Platform) {
    "win2016" {
        switch ( $Language ) {
            "jpn" {
                Write-Host( "Set the language used by the user to Japanese")
                Set-WinUserLanguageList -LanguageList ja-JP,en-US -Force

                Write-Host( "Overwrite the input language with Japanese" )
                Set-WinDefaultInputMethodOverride -InputTip "0411:00000411"
            }
        }
    }
    "win2019" {
        switch ( $Language ) {
            "jpn" {
                Write-Host( "Set the language used by the user to Japanese")
                Set-WinUserLanguageList -LanguageList ja-JP,en-US -Force

                Write-Host( "Overwrite the input language with Japanese" )
                Set-WinDefaultInputMethodOverride -InputTip "0411:00000411"

                # This code throws an exception of type system.exception when executed through Remote Powershell
                # Write-Host( "Set the input method to MS-IME.")
                # Set-WinLanguageBarOption -UseLegacySwitchMode -UseLegacyLanguageBar
            }
        }
    }
    "win2022" {
        switch ( $Language ) {
            "jpn" {
                Write-Host( "Set the language used by the user to Japanese")
                Set-WinUserLanguageList -LanguageList ja-JP,en-US -Force

                Write-Host( "Overwrite the input language with Japanese" )
                Set-WinDefaultInputMethodOverride -InputTip "0411:00000411"
            }
        }
    }
}
Start-Sleep -Seconds 30
Restart-Computer -ErrorAction SilentlyContinue