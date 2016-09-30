#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# This PS module contains functions for Desired State Configuration (DSC) NuGet provider. It enables find, get, install, 
# and uninstall NuGet packages through DSC Get, Set and Test operations on DSC managed nodes.

Import-LocalizedData  -BindingVariable LocalizedData -filename MSFT_NugetPackage.strings.psd1 

Import-Module -Name "$PSScriptRoot\..\OneGetHelper.psm1"

#DSC Resource for the $CurrentProviderName
$CurrentProviderName="NuGet"


function Get-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download packages from the Nuget source 
    location and install it on your computer. 

    Get-TargetResource returns the current state of the resource.

    .PARAMETER Name
    Specifies the name of the package to be installed or uninstalled.

    .PARAMETER DestinationPath
    Specifies a file location where you want the package to be installed.

    .PARAMETER RequiredVersion
    Provides the version of the package you want to install or uninstall.

    .PARAMETER MaximumVersion
    Provides the maximum version of the package you want to install or uninstall.

    .PARAMETER MinimumVersion
    Provides the minimum version of the package you want to install or uninstall.
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $DestinationPath,

        [System.String]
        $RequiredVersion,

        [System.String]
        $MaximumVersion,

        [System.String]
        $MinimumVersion
    )
        
    #validate version info
    $version = ExtractArguments -FunctionBoundParameters $PSBoundParameters -ArgumentNames ("MinimumVersion", "MaximumVersion", "RequiredVersion")
  
    ValidateVersionArgument @version

    #init $Ensure variable
    $ensure = 'Absent'
     
    #Add Nuget provider and Destination to the PSBoundParameters
    $PSBoundParameters.Add("ProviderName", $CurrentProviderName)
    $PSBoundParameters.Add("Destination", $DestinationPath)
    $PSBoundParameters.Remove('DestinationPath')

    Write-Verbose -Message ($localizedData.StartGetPackage -f $($Name))
 
    $packages =  PackageManagement\Get-Package @PSBoundParameters -ForceBootstrap -ErrorAction SilentlyContinue -WarningAction SilentlyContinue                                    

    #If the package is found, the count > 0. 
     
    if ($packages.Name.Count -gt 0) 
    {
        $ensure = 'Present'

        Write-Verbose -Message ($localizedData.PackageFound -f "$($Name).$($packages.Version)")       
    }
    else
    {
        Write-Verbose -Message ($localizedData.PackageNotFound -f "$($Name).$($packages.Version)")
    }
        
    Write-Debug -message "Ensure of $($Name) package is $($ensure)"

    if ($ensure -ieq 'Absent')
    {
        return @{
            Ensure              = $ensure
            Name                = $Name        
            DestinationPath     = $DestinationPath
        }
    }

    #Find a package with the latest version and return its properties
    $packageWithLatestVersion = $null

    foreach ($package in $packages)
    {
        if ($package.Version -gt $packageWithLatestVersion.Version)
        {
            $packageWithLatestVersion = $package
        }
    }

  
    #The Nuget convention <PackageName>.<Version>. Hence we need to contruct a file name here
    $itemName = $packageWithLatestVersion.Name+"."+$packageWithLatestVersion.Version
           
    #Extract the SoftwareIdentity
    $softwareIdentity = $packageWithLatestVersion | select 'swid'   
                   
    return @{
            Ensure              = $ensure
            Name                = $itemName    
            DestinationPath     = $DestinationPath
            Description         = $packageWithLatestVersion.Summary
            InstalledVersion    = $packageWithLatestVersion.Version
            Source              = $packageWithLatestVersion.Source
            SoftwareIdentity    = $softwareIdentity
            }          
}

function Test-TargetResource
{    
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download packages from the Nuget source 
    location and install it on your computer. 

    Test-TargetResource validates whether the resource is currently in the desired state.

    .PARAMETER Name
    Specifies the name of the package to be installed or uninstalled.

    .PARAMETER DestinationPath
    Specifies a file location where you want the package to be installed.

    .PARAMETER Ensure
    Determines whether the package to be installed or uninstalled.

    .PARAMETER InstallationPolicy
    Determines whether you trust the package’s source.

    .PARAMETER RequiredVersion
    Provides the version of the package you want to install or uninstall.

    .PARAMETER MaximumVersion
    Provides the maximum version of the package you want to install or uninstall.

    .PARAMETER MinimumVersion
    Provides the minimum version of the package you want to install or uninstall.

    .PARAMETER SourceCredential 
    Provides access to the package on a remote source. This property is not used to 
    install the package. The package is always installed under the local system account

    .PARAMETER Source
    Specifies the Uri or name of the registered package source.
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $DestinationPath,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present",

        [ValidateSet("Trusted","Untrusted")]
        [System.String]
        $InstallationPolicy="Untrusted",

        [System.String]
        $RequiredVersion,

        [System.String]
        $MaximumVersion,

        [System.String]
        $MinimumVersion,

        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [System.String]
        $Source
    )

    #Extract arguments to be used by Get-TargetResource. Otherwise the function call will fail.  
    $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
                                           -ArgumentNames ("Name","DestinationPath", "MaximumVersion","MinimumVersion", "RequiredVersion")

    Write-Debug -Message "Calling Get-TargetResource"
    $status = Get-TargetResource @extractedArguments


    if ($status.Ensure -eq $Ensure)
    {    

        #
        #There is a bug in the PackageManagementSourceget-package: If a Version '2.0.1' is installed but a user is 
        #asking the RequiredVersion="2.0.1.1". Get-pacakage returns 2.0.1.  
        #This means if we have 2.0.1 installed, we won't be able to install 2.0.1.1. 
        #The following is just workaround. Once the bug got fixed, replace the below code with return $true

        if ($Ensure -ieq 'Absent')
        {
            Write-Verbose -Message ($localizedData.InDesiredState -f $($Name), $($Ensure), $($status.Ensure))          
            return $true;
        }

        #A user does not provide the requiredversion, we are good
        if (-not $psboundparameters.ContainsKey("RequiredVersion"))
        {
            Write-Verbose -Message ($localizedData.InDesiredState -f $($Name), $($Ensure), $($status.Ensure))
      
            return $true
        }

        #Version matches 
        if (($psboundparameters.ContainsKey('RequiredVersion')) -and ($status.InstalledVersion -eq $RequiredVersion))
        {          
            Write-Verbose -Message ($localizedData.InDesiredState -f "$($Name).$($RequiredVersion)", $($Ensure), $($status.Ensure))
            return $true
        }
        else
        {
            #The Version does not match. This is the case when 2.0.1 is installed but a user is asking for 2.0.1.1
            Write-Verbose -Message ($localizedData.NotInDesiredStateVersionMismatch -f $($Name), $($RequiredVersion), $($status.InstalledVersion))

            return $false
        }

    }
    else
    {
        Write-Verbose -Message ($localizedData.NotInDesiredState -f $($Name),$($Ensure), $($status.Ensure))                
        return $false
    }
}
 
function Set-TargetResource
{
 <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download packages from the Nuget source 
    location and install it on your computer. 

    Set-TargetResource sets the resource to the desired state. "Make it so"..

    .PARAMETER Name
    Specifies the name of the package to be installed or uninstalled.

    .PARAMETER DestinationPath
    Specifies a file location where you want the package to be installed.

    .PARAMETER Ensure
    Determines whether the package to be installed or uninstalled.

    .PARAMETER InstallationPolicy
    Determines whether you trust the package’s source.

    .PARAMETER RequiredVersion
    Provides the version of the package you want to install or uninstall.

    .PARAMETER MaximumVersion
    Provides the maximum version of the package you want to install or uninstall.

    .PARAMETER MinimumVersion
    Provides the minimum version of the package you want to install or uninstall.

    .PARAMETER SourceCredential 
    Provides access to the package on a remote source. This property is not used to 
    install the package. The package is always installed under the local system account.

    .PARAMETER Source
    Specifies the Uri or name of the registered package source.
    #>

    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $DestinationPath,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present",

                [ValidateSet("Trusted","Untrusted")]
        [System.String]
        $InstallationPolicy="Untrusted",

        [System.String]
        $RequiredVersion,

        [System.String]
        $MaximumVersion,

        [System.String]
        $MinimumVersion,

        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [System.String]
        $Source
    )

    #Validate the source argument
    if ($PSBoundParameters.ContainsKey("Source"))
    {
        ValidateArgument -Argument $Source -Type "PackageSource" -ProviderName $CurrentProviderName
    }

    if ($PSBoundParameters.ContainsKey("SourceCredential"))
    {
        $PSBoundParameters.Add("Credential", $SourceCredential)
    }

    $PSBoundParameters.Add("ProviderName", $CurrentProviderName)
    $PSBoundParameters.Add("Destination", $DestinationPath)
    
    #Pick the set of params used by the PackageManagement Cmdlet 
    $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
                                           -ArgumentNames ("Name","Source", "MaximumVersion","MinimumVersion", "RequiredVersion", "Credential", "ProviderName")   

    if($Ensure -ieq "Present")  
    {   
        Write-Verbose -Message ($localizedData.StartFindPackage -f $($Name))

        #Check if the package exists in the repository
        $packages = PackageManagement\Find-Package @extractedArguments -Force -ErrorVariable ev      
                  
        if($ev -or (-not $packages))
        {             
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage ($localizedData.PackageNotFoundInRepository -f $Name, $ev.Exception)`
                        -ErrorId "PackageNotFoundInRepository" `
                        -ErrorCategory InvalidOperation
        }
           

        $trusted = $null
        $packageFound = $null

        foreach ($p in $packages)
        {
            #Check for the installation policy        
            $trusted = Get-InstallationPolicy -RepositoryName $p.Source -ErrorAction SilentlyContinue -WarningAction SilentlyContinue           
             
            #Stop the loop if we found a trusted repository
            if ($trusted)
            {   
                $packageFound = $p 
                break;
            }        
        }                     
         
        #The respository is trusted, so we install it
        if ($trusted)
        {                     
            Write-Verbose -Message ($localizedData.StartInstallPackage -f $Name, $packageFound.Version.toString(), $packageFound.Source) 
            $returnVal = $packageFound |  PackageManagement\Install-Package -destination $DestinationPath -ErrorVariable ev
        }
        #The repository is untrusted but user's installation policy is trusted, so we install it with a warning
        elseif ($InstallationPolicy -ieq 'Trusted')
        {
            
            if ($packages.Name.count -eq 1)
            {
                #Pick the package from the first repository. This is the case when the all repositories containing the package are untrusted
                $packageFound = $packages                
            }
            else
            {
                $packageFound = $packages[0]
            }

            # Need -force and warn the user when a user's installation policy is trusted but the repository is not
            Write-Warning -Message  ($localizedData.InstallationPolicyWarning -f $Name, $InstallationPolicy, $packageFound.Source)

            $returnVal = $packageFound |  PackageManagement\Install-Package -destination $DestinationPath -Force -ErrorVariable ev            
        }
        #Both user and repository is untrusted
        else
        {
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage ($localizedData.InstallationPolicyFailed -f $InstallationPolicy, "Untrusted") `
                        -ErrorId "InstallationPolicyFailed" `
                        -ErrorCategory InvalidOperation    
        } 
            
        if ($returnVal -and ($returnVal.Status -eq 'Installed'))
        {
            Write-Verbose -Message ($localizedData.InstalledSuccess -f "$($Name).$($returnVal.Version)")
        }
        else
        { 
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage ($localizedData.FailtoInstall -f $Name, $ev.Exception)`
                        -ErrorId "FailtoInstall" `
                        -ErrorCategory InvalidOperation
        }
    }            
    #Ensure=Absent
    else 
    {                
        #Validate if the path exists for uninstalling
        ValidateArgument   -Argument $PSBoundParameters['DestinationPath'] -Type 'DestinationPath'  -ProviderName $CurrentProviderName

        $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
                                               -ArgumentNames ("Name", "Destination", "MaximumVersion","MinimumVersion", "RequiredVersion",  "ProviderName") 

        Write-Verbose -Message ($localizedData.StartGetPackage -f $($Name))

        $packages = PackageManagement\Get-Package @extractedArguments -Force -ErrorVariable ev

        if ((-not $packages) -or $ev) 
        {  
             ThrowError -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage ($localizedData.PackageNotFound -f "$($Name).$($ev.Exception)")`
                        -ErrorId "PackageNotFound" `
                        -ErrorCategory InvalidOperation  
        }
                  
        Write-Verbose -Message ($localizedData.StartUnInstallPackage -f $($Name))
      
        $returnVal = $packages |  PackageManagement\UnInstall-Package -Force -ErrorVariable ev

        if($returnVal -and $returnVal.Status -eq 'Uninstalled')
        {
             Write-Verbose -Message ($localizedData.UnInstalledSuccess -f "$($Name).$($returnVal.Version)")
        }
        else
        {
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage ($localizedData.FailtoUninstall -f $Name, $ev.Exception)`
                        -ErrorId "FailtoInstall" `
                        -ErrorCategory InvalidOperation
        }                     
    }     
}


Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource

