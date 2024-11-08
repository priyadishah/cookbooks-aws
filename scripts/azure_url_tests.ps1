
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

    Write-Host "Waiting 5 minutes to ensure that stack has completed setup"
    Start-Sleep -Seconds 300

    Write-Host  # Blank line
    Write-Host "Running URLs"

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    forEach ($url in $urls) {
        Write-Host $url
        try{
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 14 -UseBasicParsing
            $ResponseCode = $response.StatusCode
            if($ResponseCode -ne 200) {
                Write-Host "Response code not equal to 200: $ResponseCode"
                $failureCount = $failureCount + 1
            } else {
                Write-Host $ResponseCode
            }
        } catch {
            Write-Host $_.Exception
            $ResponseCode = $_.Exception.Response.StatusCode.Value__
            $failureCount = $failureCount + 1
            Write-Host $ResponseCode
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