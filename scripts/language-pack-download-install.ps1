param(
    [Parameter(Mandatory=$true)]
    [String]
    $Language,

    [Parameter(Mandatory=$true)]
    [String]
    $Platform
)

function DownloadLanguagePack {
   param (
       [string] $Uri,
       [string] $installer_file,
       [string] $log_file
   )
   Write-Host ("Downloading $Uri to $installer_file")
   $downloaded = $false
   $TotalFailedDownloadAttempts = 0
   $loops = 0
   while (-not $Downloaded -and ($Loops -le 10) ) {
      try {
         (New-Object System.Net.WebClient).DownloadFile($Uri, $installer_file) | Out-Default | Write-Host
         $downloaded = $true
      } catch {
         $_ | Out-default | Write-Host
         $TotalFailedDownloadAttempts += 1
         $loops += 1

         Write-Host ("Total Failed Download Attempts = $TotalFailedDownloadAttempts")

         if ($loops -gt 10) {
            throw "Failed to download $Uri"
         }

         # Pause for 30 seconds. Maybe that will help it work?
         Start-Sleep 30
      }
   }
}

Write-Host "Language = $Language, Platform = $Platform"

try {
   #  Enabling TLS 1.2 security protocol to establish a secure connection with the server when making web requests.
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

   switch ( $Platform) {
      "win2016" {
         switch ( $Language ) {
               "jpn" {
                  $lpurl = "https://lansa.s3-ap-southeast-2.amazonaws.com/3rd+party/Japanese+Language+Packs/Server+2016/jpn/x64fre_Server_ja-jp_lp.cab"
                  $langcode = "ja-JP"
               }
               default {
                  throw "$Language not supported for language pack install"
               }
         }
      }
      "win2019" {
         switch ( $Language ) {
               "jpn" {
                  $lpurl = "https://lansa.s3-ap-southeast-2.amazonaws.com/3rd+party/Japanese+Language+Packs/Server+2019/jpn/Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab"
                  $langcode = "ja-JP"
               }
               default {
                  throw "$Language not supported for language pack install"
               }
         }
      }
      "win2022" {
         switch ( $Language ) {
               "jpn" {
                  $lpurl = ""
                  $langcode = "ja-JP"
               }
               default {
                  throw "$Language not supported for language pack install"

               }
         }
      }
      default {
         throw "$Platform not supported for language pack install"
      }
   }
   $lppath = "$ENV:temp\lang-pack.cab"

   DownloadLanguagePack -Uri $lpurl -installer_file $lppath
   Invoke-WebRequest -Uri $lpurl -OutFile $lppath

   # Write-Host( "Install the Japanese language Pack using the Lpksetup.exe command. Forces a reboot after installation" )
   # C:\windows\system32\Lpksetup.exe /i $langcode /f /s /p $lppath

   Write-Host( "Install the Japanese language Pack using dism.exe command. It does not force a reboot after installation so do it explicitly" )
   dism.exe /Online /Add-Package /PackagePath:$lppath

   # This method is only available on client operating systems. Not on Server operating systems
   # Write-Host( "Install the language pack using PowerShell in-built cmdlet")
   # Install-Language -Language $langcode | Out-Default | Write-Host

   Start-Sleep -Seconds 30
   Write-Host "Language Pack installation succeeded"
   cmd /c exit 0
   Restart-Computer
} catch {
   $_ | Out-default | Write-Host
   cmd /c exit 1
   throw "Language Pack installation failed"
}