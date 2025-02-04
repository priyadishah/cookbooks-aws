
param (
    [Parameter(Mandatory=$true)]
    [string]
    $deploymentOutput,

    [Parameter(Mandatory=$false)]
    [string]
    $Language = 'ENG',

    [Parameter(Mandatory=$false)]
    [decimal]
    $TestSetParam = 15

)
[Flags()] enum TestType {
    Probe = 1
    About = 2
    WAM = 4
    Integrator = 8
}

add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@

$failureCount = 0
$urls = @()
try {
    [TestType]$TestSet = $TestSetParam

    Write-Host "DeploymentOutput is $deploymentOutput"
    Write-Host "Language is $Language"
    Write-Host "TestSet = $TestSet"

    # Use the deployment output to extract the IpAddress
    $sqlazureDeploymentOutput=ConvertFrom-Json $deploymentOutput
    $IpAddress = $sqlazureDeploymentOutput.lbFqdn.value
    $url1 = "$IpAddress/cgi-bin/probe"
    $url2 = "$IpAddress/cgi-bin/lansaweb?about"

    if($Language -eq 'JPN') {
        $url3 = "$IpAddress/JPNTESTs/TEST"
        $url4 = "$IpAddress/JPNTESTs/DUMMY"
    } else {
        $url3 = "$IpAddress/cgi-bin/lansaweb?wam=DEPTABWA&webrtn=BuildFirst&ml=LANSA:XHTML&part=DEX&lang=ENG"
        $url4 = "$IpAddress/cgi-bin/lansaweb?wam=JSMLICE&webrtn=weblic&ml=LANSA:XHTML&part=DEX&lang=ENG"
    }

    if ($TestSet.HasFlag([TestType]::Probe) ) {
        $urls += $url1
    }

    if ($TestSet.HasFlag([TestType]::About) ) {
        $urls += $url2
    }

    if ($TestSet.HasFlag([TestType]::WAM) ) {
        $urls += $url3
    }

    if ($TestSet.HasFlag([TestType]::Integrator) ) {
        $urls += $url4
    }

    Write-Host "URLs to be run..."
    $urls | Format-List | Out-Default | Write-Host

    Write-Host  # Blank line
    Write-Host "Running URLs"

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    Write-Host( "Call each URL twice to log the response time for the second call")
    for ($i = 1; $i -le 2; $i++) {
      Write-Host( "Loop $i")
      forEach ($url in $urls) {
         Write-Host $url
         # Only reset the timeout the first loop. The second loop will fail immediately if the first loop ended due to timing out completely.
         if ( $i -eq 1){
            $Timeout = 0
         }
         do {
            try{
               # Increasing this timeout from 14 to 120 has fixed some of the issues to do with timing.
               $ResponseCode = 0
               $response = Invoke-WebRequest -Uri $url -TimeoutSec 120 -UseBasicParsing
               $ResponseCode = $response.StatusCode
               if($ResponseCode -eq 200) {
                  Write-Host $ResponseCode
               } else {
                  # This is not expected to be executed as Invoke-WebRequest has only been seen to throw when response is not 200
                  throw "ResponseCode = $ResponseCode"
               }
            } catch {
               Write-Host $_.Exception
               if ( $_.Exception.Response.StatusCode.Value__) {
                  $ResponseCode = $_.Exception.Response.StatusCode.Value__
                  # A timeout returns 200, which makes the request successful, which it clearly isn't
                  if ($ResponseCode -eq 200) {
                     $ResponseCode = 0
                  }
               }
               $Timeout += 1 # This timeout is seen quite frequently, usually just the once (one check revealed 3 occurences in 28 runs of this script), and then the next web request works (500 internal server error)
               Write-Host "Response Code = $ResponseCode. Timeout = $Timeout. Waiting 30 seconds..."
               Start-Sleep -Seconds 30 # If a timeout is occuring on the web request then a further 2 mins needs to be added to this to get the total timeout
            }
         } until ($ResponseCode -eq 200 -or $Timeout -ge 6) # Between minimum 3 and maximum 15 minute timeout

         if ($ResponseCode -ne 200) {
            $failureCount = $failureCount + 1
         }
      }
   }

    if ($failureCount) {
        Write-Host "Request failed for $($failureCount) URL(s)"
        throw "The deployment failed the URL tests"
    }

} catch {
    $_ | Write-Error
    throw "Error Testing URLS"
}

Write-Host "Successfully tested all URL(s)"