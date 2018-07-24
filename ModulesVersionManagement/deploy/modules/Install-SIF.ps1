function Invoke-FixIoXmlTaskBug {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $false)]
        [string]$CodeFile = "C:\Program Files\WindowsPowerShell\Modules\SitecoreInstallFramework\1.2.1\Public\Tasks\Invoke-IoXmlTask.ps1",
        [parameter(Mandatory = $false)]
        [string]$BrokendCodeLine = 'Write-Verbose "$($ioXml.IOActions.IOAction.Count) IO Action(s) detected."'
    )
    PROCESS {   
        if (Test-Path $CodeFile) {
            $content = Get-Content $CodeFile | Out-String
            $CommentedOutLine = "#$($BrokendCodeLine)";
            if (-Not $content.Contains($CommentedOutLine)) {
                if (-Not $content.Contains($BrokendCodeLine)) {
                    Write-Host "FixIoXmlTaskBug: The bug has been already fixed by vendor (Sitecore)."
                }
                else {                
                    Write-Host "FixIoXmlTaskBug: Commenting out line '$($BrokendCodeLine)' in $($CodeFile) file."
                    $content = $content.replace($BrokendCodeLine, $CommentedOutLine)
                    Set-Content -Path $CodeFile -Value $content
                }
            }
            else {
                Write-Host "FixIoXmlTaskBug: Broken code line is already commented out."
            }
        }
    }
}
# Add the Sitecore MyGet repository to PowerShell
if (-not $($(Get-PSRepository).Name -eq "SitecoreGallery") -eq "SitecoreGallery") {
    Write-Host "Registering SitecoreGallery Repository"
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2 -InstallationPolicy Trusted
    #Unregister-PSRepository -Name SitecoreGallery
    Write-Host "Registered SitecoreGallery Repository"
}
else {
    Write-Host "SitecoreGallery Repository is already registered"
}

# # Import SIF Modules
if (-not (Get-Module SitecoreInstallFramework)) {    
    Write-Host "Installing SitecoreInstallFramework"
    Install-Module SitecoreInstallFramework -Force
    #Remove-Module SitecoreInstallFramework
    #Remove-Module SitecoreFundamentals
    Write-Host "Installed SitecoreInstallFramework"

    Invoke-FixIoXmlTaskBug
}
else {
    Write-Host "SitecoreInstallFramework is already installed"
}
Write-Host "Get-Module SitecoreInstallFramework:"
Get-Module SitecoreInstallFramework