#Check Installed SQL Server Data Tools Version
function CheckSqlDataToolsInstallation {
    # Update execution policy
    #$currentProcessExecutionPolicy = Get-ExecutionPolicy -Scope Process
    #Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

    if (![System.IO.File]::Exists("C:\Program Files (x86)\Microsoft SQL Server\140\Tools\Binn\ManagementStudio\Extensions\Application\Microsoft.SqlServer.TransactSql.ScriptDom.dll") -Or 
        ![System.IO.File]::Exists("C:\Program Files (x86)\Microsoft SQL Server\130\Tools\Binn\ManagementStudio\Extensions\Application\Microsoft.SqlServer.TransactSql.ScriptDom.dll")) {
        Write-TaskInfo -Tag "SQL Data Tools" -Message "Please check installation..."
    }
    #Set-ExecutionPolicy $currentProcessExecutionPolicy Scope -Process
}

function Invoke-AddUserToLocalGroup {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
		[parameter(Mandatory = $true)]
		[string]$SiteName,
		[parameter(Mandatory = $true)]
		[string]$GroupName
    )
	PROCESS { 
		$userName = "IIS APPPOOL\$SiteName"
		
        $groupObj =[ADSI]"WinNT://./$GroupName,group"  
        try{
            $membersObj = @($groupObj.psbase.Invoke("Members")) 
        }
        catch{
            Write-TaskInfo "If you are using non-English Windows OS, for example you are in France then please rename User group 'Utilisateurs du journal de performances' to 'Performance Log Users' and try again."  -Tag 'AddUserToLocalGroup'
            throw
        }

        $members = ($membersObj | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)})
		
        If ($members -contains $SiteName) {
		   Write-TaskInfo "User {$UserName} exists in {$GroupName}" -Tag 'AddUserToLocalGroup'
		}
		else
		{
		  Write-TaskInfo "Adding user {$UserName} to Group {$GroupName}" -Tag 'AddUserToLocalGroup'
		  Add-LocalGroupMember -Group $GroupName -Member $userName
		}		
		
	}
}

#Create the SQL Login user wsf..
function Invoke-CreateSqlLogin {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true)]
        [string]$Server,
        [parameter(Mandatory = $true)]
        [string]$User,
        [parameter(Mandatory = $true)]
        [string]$Password,
        [parameter(Mandatory = $false)]
        $LoginType = "SqlLogin"
    )

    PROCESS {
        CheckSqlDataToolsInstallation

        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted  
        Install-Module sqlserver -Confirm:$False  
        Install-Module dbatools -Confirm:$False  
        Import-Module sqlserver  
        Import-Module dbatools
        

        #check to see if login already exists
        $Login = Get-SqlLogin -ServerInstance $Server -LoginName $User
    
        if (!($Login)) {
            Write-TaskInfo -Tag "SQL Login: " + $User  -Message "Doesn't exist, creating SQL user..."
            #$pass = ConvertTo-SecureString -String "wsf" -AsPlainText -Force
            Write-TaskInfo -Tag "Creating SQL User.. " -Message "User:" + $User + "Pass: " + $Password
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password
            Add-SqlLogin -ServerInstance $Server -LoginName $User -LoginType $LoginType -DefaultDatabase tempdb -Enable -GrantConnectSql -LoginPSCredential $Credential  
            $svr = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $Server
            $svrole = $svr.Roles | where {$_.Name -eq 'sysadmin'}
            $svrole.AddMember($User)
        } 
        else {
            Write-TaskInfo -Tag  "SQL Login: " + $User -Message " already exists"
        }
    }
}

function Invoke-DeleteFile() {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true)]
        [string]$Path
    )    
    PROCESS {           
        Remove-Item -Path $Path -Verbose -Force
    }
}

function Invoke-DeleteFilesRecursively() {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true)]
        [string]$RootDirectoryPath,
        [parameter(Mandatory = $true)]
        [string]$FileNamePattern
    )    
    PROCESS {   
        Get-ChildItem -Path $RootDirectoryPath -Filter $FileNamePattern -Recurse -ErrorAction SilentlyContinue -Force | foreach ($_) {
            remove-item $_.fullname -Verbose -Force
        }
    }
}

# Set Azure Search
function Invoke-DeployBootloadCargoPayloadPackage() {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true)]
        [string]$TransformsFolder,
        [parameter(Mandatory = $true)]
        [string]$PackagePath
    )
    PROCESS {   
        Write-TaskInfo -Tag "Deploying Cargo Payload Pakcage" -Message $PackagePath
        Invoke-EnsurePathTask -Exists $TransformsFolder
        Copy-Item -Path $PackagePath -Destination $TransformsFolder -Verbose -Force
    }
}


    #dropbox data reader
function Invoke-GetDropBoxPathFromInfoJson()
{
        [CmdletBinding(SupportsShouldProcess = $true)]
        param()

        PROCESS {  
            $dropboxLicense = 'business'  # it could be business or private section at JSON file. it depends on version of Dropbox license
            $DropboxPath = Get-Content "$ENV:LOCALAPPDATA\Dropbox\info.json" -ErrorAction Stop | ConvertFrom-Json | % $dropboxLicense | % 'path'
            return $DropboxPath
        }

}

function Invoke-GetDropBoxFolder()
{
            [CmdletBinding(SupportsShouldProcess = $true)]
            param()
            PROCESS {  
                $dropboxFolderName = "L_OREAL_WFS_SITECORE_INSTALLER"
                $dropboxLocal = Get-DropBoxPathFromInfoJson

                $dropBoxLocalPath = Join-Path -Path $dropboxLocal -ChildPath $dropboxFolderName
                Write-Host $dropBoxLocalPath
                if (-not (Test-Path -Path $dropBoxLocalPath)) 
                { 
                    throw "Path '$dropBoxLocalPath' not found! Please download '$dropboxFolderName' to your local dropbox"
                }
                return $dropBoxLocalPath
            }
}

Register-SitecoreInstallExtension -Command Invoke-GetDropBoxFolder -As GetDropBoxFolder -Type Task

Register-SitecoreInstallExtension -Command Invoke-AddUserToLocalGroup -As AddUserToLocalGroup -Type Task
Register-SitecoreInstallExtension -Command Invoke-CreateSqlLogin -As CreateSqlLogin -Type Task
Register-SitecoreInstallExtension -Command Invoke-DeleteFile -As DeleteFile -Type Task
Register-SitecoreInstallExtension -Command Invoke-DeleteFilesRecursively -As DeleteFilesRecursively -Type Task
Register-SitecoreInstallExtension -Command Invoke-DeployBootloadCargoPayloadPackage -As DeployBootloadCargoPayloadPackage -Type Task