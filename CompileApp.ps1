#install bccontainerhelper 
Write-Host "##[command]Installing BcContainerHelper"
Install-Module -Name bccontainerhelper -Force
$module = Get-InstalledModule -Name bccontainerhelper -ErrorAction Ignore
$versionStr = $module.Version.ToString()
Write-Host "##[section]BcContainerHelper $VersionStr installed"
#install bccontainerhelper




#creating container
$RepositoryDirectory = Get-Location

$ContainerName = 'BcConteiner'
$password = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ('admin', $password)
$stop = false;

try { 
    Get-BcContainerId -containerName $ContainerName
    Start-BcContainer -containerName $ContainerName
}
catch {  
    $artifactUrl = Get-BCArtifactUrl -country w1 -select Latest -storageAccount bcartifacts -type Sandbox

    $AdditionalParameters = @()
    $AdditionalParameters += '--volume "{0}:{1}"' -f $RepositoryDirectory, 'c:\sources'
    
    $Params = @{}
    $Params += @{ accept_eula = $true }
    $Params += @{ artifactUrl = $artifactUrl }
    $Params += @{ containerName = $ContainerName }
    $Params += @{ auth = 'NavUserPassword' }
    $Params += @{ credential = $Credential }
    $Params += @{ isolation = 'process' }
    $Params += @{ memoryLimit = '8GB' }
    $Params += @{ accept_outdated = $true }
    $Params += @{ useBestContainerOS = $true }
    $Params += @{ additionalParameters = $AdditionalParameters }
    
    New-BcContainer @Params -shortcuts None
    #creating container
}




#increase app version
$app = (Get-Content "app.json" -Encoding UTF8 | ConvertFrom-Json)
$existingVersion = $app.version -as [version]
$versionBuild = Get-Date -Format "yyyyMMdd"
$versionRevision = Get-Date -Format "HHmmss"
$nextVersion = [version]::new($existingVersion.Major, $existingVersion.Minor, $versionBuild, $versionRevision)
$app.version = "$nextVersion"
$app | ConvertTo-Json | Set-Content app.json
write-host "##[section]Version increased to $nextVersion"
#increase app version

#compile app
write-host "##[command]Compiling app" $app.Name $app.Version
Compile-AppInBcContainer -appProjectFolder $RepositoryDirectory -containerName $ContainerName -credential $Credential -GenerateReportLayout Yes -ReportSuppressedDiagnostics -AzureDevOps -EnableCodeCop -EnablePerTenantExtensionCop 
#compile app

#copy app to build staging directory
write-host "##[section]Moving app to build staging directory"
Copy-Item -Path (Join-Path $RepositoryDirectory -ChildPath("\output\" + $app.publisher + "_" + $app.Name + "_" + $app.Version + ".app")) -Destination $env:Build_StagingDirectory
Copy-Item -Path (Join-Path $RepositoryDirectory -ChildPath("PublishApp.ps1")) -Destination $env:Build_StagingDirectory
write-host "##[section]Staging directory $env:Build_StagingDirectory"
#copy app to build staging directory

#updating build pipeline number
Write-Host "##vso[build.updatebuildnumber]$nextVersion"
#updating build pipeline number 

if($stop) {
    Write-Host "##[command]Stoping Container"
    Stop-BcContainer -containerName $ContainerName
}