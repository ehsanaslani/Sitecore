# Install and Import SIF
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
.\modules\Install-SIF.ps1

$DeploymentRoot = ((Get-Item -Path "." -Verbose).FullName)
$SolutionRoot = ((Get-Item -Path ".." -Verbose).FullName)
$SitecoreSiteName = "sitecore-demo"
$SqlServer = "."
$SqlAdminUser = "wsf"
$SqlAdminPassword = "wsf"

$SitecoreParams =
@{
    Path = "$($DeploymentRoot)\configuration\xp-sitecore-cm-82-pse-sxa.json"
    InstallDirectory = "$($SolutionRoot)\build"
    LicenseFile = "$($DeploymentRoot)\packages\license.xml"
    SqlDbPrefix = $SitecoreSiteName
    SqlServer = "Data Source=$($SqlServer);User ID=$($SqlAdminUser);password=$($SqlAdminPassword);Database=" #$SqlServer
    Sitename = $SitecoreSiteName
    #Sitecore WDP package
    Package = "$DeploymentRoot\packages\Sitecore 8.2 rev. 180406_single.scwdp.zip"
    #Cargo Payload Transforms
    CargoPayloadsDirectory = "$($DeploymentRoot)\packages\CargoPayloads"
    IoXmlDirectory = "$($DeploymentRoot)\modules\ioxml"
    #Sitecore Module WDP packages
    Package_Bootload = "$($DeploymentRoot)\packages\Sitecore.Cloud.Integration.Bootload.wdp.zip"
    Package_Powershell = "$DeploymentRoot\packages\Sitecore PowerShell Extensions-4.6 for Sitecore 8.scwdp.zip"
    Package_SXA = "$DeploymentRoot\packages\Sitecore PowerShell Extensions-4.6 for Sitecore 8.scwdp.zip"
}

Install-SitecoreConfiguration @SitecoreParams -Verbose