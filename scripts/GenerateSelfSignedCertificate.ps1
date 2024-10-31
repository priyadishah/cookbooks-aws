Param(
    [Parameter(Mandatory)]
        [String] $Pwd
)

$CertPath = 'cert:\localmachine\my'
$PfxPath = 'c:\appgwcert.pfx'
Remove-Item $PfxPath -ErrorAction SilentlyContinue
$ExpiryDate = Get-Date -date "2099-12-31"
$Cert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname www.contoso.com -NotAfter $ExpiryDate
$cert

$SecurePassword = ConvertTo-SecureString $Pwd -AsPlainText -Force
Export-PfxCertificate -cert "$CertPath\$($Cert.Thumbprint)" -FilePath $PfxPath -Password $SecurePassword

[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($PfxPath))