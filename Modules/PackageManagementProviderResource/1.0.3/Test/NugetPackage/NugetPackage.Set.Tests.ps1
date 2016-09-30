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
$CurrentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

.  "$CurrentDirectory\..\OneGetTestHelper.ps1"

#
# Pre-Requisite: MyTestPackage.12.0.1.1, MyTestPackage.12.0.1, MyTestPackage.15.2.1 packages are available under the $LocalRepositoryPath. 
# It's been taken care of by SetupNugetTest
#
 
# Calling the setup function 
SetupNugetTest
 
Describe -Name  "NugetPackage Set-TargetResource Basic Test" -Tags "BVT" {

    BeforeEach {

        #Remove all left over files if exists
        Remove-Item "$($DestinationPath)" -Recurse -Force -ErrorAction SilentlyContinue

    }

    AfterEach {

    }

    Context "NugetPackage Set-TargetResource Basic Test" {


        It "Set-TargetResource with RequiredVersion: Check Installed & UnInstalled" {

            RegisterPackageSource -Name "NugetTestSourceName" -InstallationPolicy Trusted  -Ensure Present -SourceUri $LocalRepositoryPath

            $result = MSFT_NugetPackage\Set-TargetResource  -Name "MyTestPackage"  `
                                                            -DestinationPath $DestinationPath  `
                                                            -RequiredVersion "12.0.1" `
                                                            -Ensure Present

            # Validate the package is installed
            Test-Path -Path "$($DestinationPath)\MyTestPackage.12.0.1" | should be $true


            # Calling Set-TargetResource in the NugetPackage resource to uninstall it 
            $result = MSFT_NugetPackage\Set-TargetResource  -Name "MyTestPackage"  `
                                                            -DestinationPath $DestinationPath  `
                                                            -RequiredVersion "12.0.1" `
                                                            -Ensure Absent

            # Package should not be there
            Test-Path -Path "$($DestinationPath)\MyTestPackage.12.0.1" | should be $false
        }

        It "Set-TargetResource with Trusted Source, No Versions Specified: Check Installed" {
           
            # Calling Set-TargetResource in the NugetPackage resource with trusted policy

             RegisterPackageSource -Name "NugetTestSourceName" -InstallationPolicy Trusted  -Ensure Present -SourceUri $LocalRepositoryPath

            # User's installation policy is untrusted by default
            $result = MSFT_NugetPackage\Set-TargetResource -Name "MyTestPackage" -DestinationPath $DestinationPath -Source "NugetTestSourceName"

            # Validate the package is installed. 2.1.3 is the latest in the local source

            Test-Path -Path "$($DestinationPath)\MyTestPackage.15.2.1" | should be $false
        }
    
 

        It "Set-TargetResource with untrusted Source and trusted user policy: Check Warning & Installed" {
           
            # Calling Set-TargetResource in the NugetPackage resource with untrusted policy

             RegisterPackageSource -Name "NugetTestSourceName" -Ensure Present -SourceUri $LocalRepositoryPath

            # User's installation policy is trusted
            $result = MSFT_NugetPackage\Set-TargetResource  -Name "MyTestPackage" `
                                                            -DestinationPath $DestinationPath `
                                                            -Source "NugetTestSourceName" `
                                                            -InstallationPolicy Trusted `
                                                            -WarningVariable wv


            if ($wv)
            {
                # Check the warning message
                $wv -imatch "untrusted repository"
                               
                # The package should be installed
                $result = MSFT_NugetPackage\Test-TargetResource -name "MyTestPackage" -DestinationPath $DestinationPath -Ensure "Present" -Source "NugetTestSourceName"
                
                $result| should be $true

                return
            }
           
            Throw "Expecting InstallationPolicyWarning but not happen" 
 
        }

               
        It "Set-TargetResource with mulitple sources containing the same package: Check Installed" {
           
            try
            {
                # registering multiple source
                RegisterPackageSource -Name "NugetTestSourceName10"   -Ensure Present -SourceUri $LocalRepositoryPath 
                RegisterPackageSource -Name "NugetTestSourceName20"   -Ensure Present -SourceUri $LocalRepositoryPath -InstallationPolicy Trusted
                RegisterPackageSource -Name "NugetTestSourceName30"   -Ensure Present -SourceUri $LocalRepositoryPath 

                # User's installation policy is untrusted
                $result = MSFT_NugetPackage\Set-TargetResource -Name "MyTestPackage" -DestinationPath $DestinationPath

                # The package should be installed
                MSFT_NugetPackage\Test-TargetResource -Name "MyTestPackage" -DestinationPath $destinationPath -Source "NugetTestSourceName20" | should be $true
            }
            finally
            {
                #unregister them
                RegisterPackageSource -Name "NugetTestSourceName10"   -Ensure Absent -SourceUri $LocalRepositoryPath 
                RegisterPackageSource -Name "NugetTestSourceName20"   -Ensure Absent -SourceUri $LocalRepositoryPath -InstallationPolicy Trusted
                RegisterPackageSource -Name "NugetTestSourceName30"   -Ensure Absent -SourceUri $LocalRepositoryPath 
            }

        }
       
        It "Set-TargetResource with SourceCredential: Check Installed" {
           
            $credential = (CreateCredObject -Name ".\Administrator" -PSCode "MassRules!")

            # Calling Set-TargetResource in the NugetPackage resource with SourceCredential
            $result = MSFT_NugetPackage\Set-TargetResource  -Name "MyTestPackage" `
                                                            -DestinationPath $DestinationPath `
                                                            -Source $LocalRepositoryPath `
                                                            -SourceCredential $credential `
                                                            -InstallationPolicy Trusted

            # Validate the package is installed
            MSFT_NugetPackage\Test-TargetResource -Name "MyTestPackage" -DestinationPath $destinationPath -Source "NugetTestSourceName" | should be $true
        }
        
    }#context

}#Describe

Describe -Name "NugetPackage Set-TargetResource Error Cases" -Tags "RI" {

    BeforeEach {

        #Remove all left over files if exists
        Remove-Item "$($DestinationPath)" -Recurse -Force -ErrorAction SilentlyContinue

        RegisterPackageSource -Name "NugetTestSourceName" -Ensure Present -SourceUri $LocalRepositoryPath -InstallationPolicy Trusted
    }

    AfterEach {
        RegisterPackageSource -Name "NugetTestSourceName" -Ensure Absent -SourceUri $LocalRepositoryPath
    }


    Context "NugetPackage Set-TargetResource Error Cases" {
            
        It "Set-TargetResource with package not found for the install: Check Error" {

            #every slow need mock
            try
            {
                # None-exist package for install
                $result = MSFT_NugetPackage\Set-TargetResource -Name "MyTestPackageyyyy" -DestinationPath $DestinationPath -Ensure Present -ErrorAction SilentlyContinue
                
            }
            Catch
            {
                #Expect fail to install.
                $_.FullyQualifiedErrorId | should be "PackageNotFoundInRepository"
                return
            }
   
            Throw "Expecting PackageNotFoundInRepository but not happen" 
        }

          
        It "Set-TargetResource with package not found for the uninstall: Check Error" {
           
            # Create a folder that is mimicking the package is installed 
            if (-not (Test-Path -Path $DestinationPath))
            {
                New-Item -Path $DestinationPath
            } 

            try
            {
                # None-exist package for uninstall
                $result = MSFT_NugetPackage\Set-TargetResource -Name "MyTestPackageyyyy" -DestinationPath $DestinationPath -Ensure Absent -ErrorAction SilentlyContinue
            }
            Catch
            {
                #Expect fail to install.
                $_.FullyQualifiedErrorId | should be "PackageNotFound"
                return
            } 
            
            Throw "Expecting PackageNotFound but not happen"  
        }                   
     
        It "Set-TargetResource with Untrusted User InstallationPolicy and Source: Check Error" {
            
            # No install will happen if both user and source are untrusted

            RegisterPackageSource -Name "NugetTestSourceName"  -Ensure Present -SourceUri $LocalRepositoryPath

            Try
            {
                # User's installation policy is untrusted.
                $result = MSFT_NugetPackage\Set-TargetResource -Name "MyTestPackage" `
                                                                -DestinationPath $DestinationPath `
                                                                -Source "NugetTestSourceName" `
                                                                -InstallationPolicy Untrusted `
                                                                -ErrorVariable ev

            }
            Catch
            {
                #Expect fail to install.
                $_.FullyQualifiedErrorId | should be "InstallationPolicyFailed"
                return
            }

            
            Throw "Expecting InstallationPolicyFailed but not happen"            
        } 

    }#context
}#Describe
