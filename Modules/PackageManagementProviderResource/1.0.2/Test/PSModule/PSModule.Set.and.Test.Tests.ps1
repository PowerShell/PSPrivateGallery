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
# Pre-Requisite: MyTestModule 1.1, 1.1.2, 3.2.1 modules are available under the $LocalRepositoryPath for testing purpose only.
# It's been taken care of by SetupPSModuleTest
#

#Calling the setup function 
SetupPSModuleTest

# We will be focusing on the tests around installation policy, versions, and multiple repositories, as we have covered basics in the get tests already.
Describe -Name "PSModule Set, Test-TargetResource Basic Test" -Tags "BVT"{

    BeforeEach {

        #Remove all left over files if exists
        Remove-Item "$($InstallationFolder)\..\..\MyTestModule" -Recurse -Force  -ErrorAction SilentlyContinue      
        Remove-Item "$($InstallationFolder)\..\MyTestModule" -Recurse -Force  -ErrorAction SilentlyContinue      
    }

    AfterEach {

    }
      
    Context "PSModule Set, Test-TargetResource Basic Test" {       
 
        It "Set, Test-TargetResource with Trusted Source, No Versions Specified: Check Installed" {
           
            #Register a local module repository to make the test run faster
            RegisterRepository -Name "LocalRepository" -InstallationPolicy Trusted -Ensure Present

            # 'BeforeEach' removes all specific modules under the $module path, so it is expected Set-Target* should success in the installation
            MSFT_PSModule\Set-TargetResource -name "MyTestModule" -Repository $LocalRepository  -Ensure Present -Verbose

            # Validate the module is installed
            $result = MSFT_PSModule\Test-TargetResource -name "MyTestModule" -Repository $LocalRepository  -Ensure Present

            $result| should be $true

            # Uninstalling the module
            MSFT_PSModule\Set-TargetResource -name "MyTestModule" -Repository $LocalRepository  -Ensure Absent -Verbose

            # Validate the module is uninstalled
            $result = MSFT_PSModule\Test-TargetResource -name "MyTestModule" -Repository $LocalRepository  -Ensure Absent

            $result| should be $true
        }

        It "Set, Test-TargetResource with Trusted Source, No respository Specified: Check Installed" {
           
            #Register a local module repository to make the test run faster
            RegisterRepository -Name "LocalRepository" -InstallationPolicy Trusted -Ensure Present

            # 'BeforeEach' removes all specific modules under the $module path, so it is expected Set-Target* should success in the installation
            MSFT_PSModule\Set-TargetResource -name "MyTestModule" -Ensure Present -Verbose

            # Validate the module is installed
            $result = MSFT_PSModule\Test-TargetResource -name "MyTestModule" -Ensure Present

            $result| should be $true

            # Uninstalling the module
            MSFT_PSModule\Set-TargetResource -name "MyTestModule" -Ensure Absent -Verbose

            # Validate the module is uninstalled
            $result = MSFT_PSModule\Test-TargetResource -name "MyTestModule" -Ensure Absent

            $result| should be $true
        }

        It "Set, Test-TargetResource with untrusted source and trusted user policy: Check Warning" {
           
            # Registering repository with untrusted installation policy
            RegisterRepository -Name "LocalRepository" -InstallationPolicy Untrusted -Ensure Present


            # User's installation policy is trusted
            $result = MSFT_PSModule\Set-TargetResource  -Name "MyTestModule" `
                                                            -Repository $LocalRepository `
                                                            -InstallationPolicy Trusted `
                                                            -WarningVariable wv

            if ($wv)
            {
                # Check the warning message
                $wv -imatch "untrusted repository"
                               
                # The module should be installed
                $result = MSFT_PSModule\Test-TargetResource -name "MyTestModule" -Repository $LocalRepository  -Ensure "Present"
                
                $result| should be $true

                return
            }
           
            Throw "Expecting InstallationPolicyWarning but not happen"    
        }

               
        It "Set, Test-TargetResource with multiple sources and versions of a modules: Check Installed" {
           
            # Registering multiple source

            $returnVal = $null

            try
            {
                $returnVal = CleanupRepository
                
                RegisterRepository -Name "LocalRepository1" -InstallationPolicy Untrusted -Ensure Present -SourceLocation $LocalRepositoryPath1 -PublishLocation $LocalRepositoryPath1

                RegisterRepository -Name "LocalRepository2" -InstallationPolicy Trusted -Ensure Present -SourceLocation $LocalRepositoryPath2 -PublishLocation $LocalRepositoryPath2

                RegisterRepository -Name "LocalRepository3" -InstallationPolicy Untrusted -Ensure Present -SourceLocation $LocalRepositoryPath3 -PublishLocation $LocalRepositoryPath3
                
                # User's installation policy is untrusted
                MSFT_PSModule\Set-TargetResource -name "MyTestModule" -Ensure "Present" -Verbose -Repository "LocalRepository2"

                # The module from the trusted source should be installed
                $result = MSFT_PSModule\Test-TargetResource -name "MyTestModule" -Repository "LocalRepository2"  -Ensure "Present"
                
                $result| should be $true
            }
            finally
            {
                RestoreRepository -RepositoryInfo $returnVal
                # Unregistering the repository sources
            
                RegisterRepository -Name "LocalRepository1" -Ensure Absent -SourceLocation $LocalRepositoryPath1 -PublishLocation $LocalRepositoryPath1

                RegisterRepository -Name "LocalRepository2" -Ensure Absent -SourceLocation $LocalRepositoryPath2 -PublishLocation $LocalRepositoryPath2

                RegisterRepository -Name "LocalRepository3" -Ensure Absent -SourceLocation $LocalRepositoryPath3 -PublishLocation $LocalRepositoryPath3
            }
        }  
        
            
    }#context

    Context "PSModule Set-TargetResource Error Cases" {

        #Register a local module repository to make the test run faster
        RegisterRepository -Name "LocalRepository" -InstallationPolicy Trusted -Ensure Present

        It "Set-TargetResource with module not found for the install: Check Error" {

            try
            {
                # The module does not exist
                MSFT_PSModule\Set-TargetResource -name "NonExistModule" -Ensure Present -ErrorAction SilentlyContinue 2>&1
            }
            catch
            {
                #Expect fail to install.
                $_.FullyQualifiedErrorId | should be "ModuleNotFoundInRepository"
                return
            }
   
            Throw "Expected 'ModuleNotFoundInRepository' exception did not happen"  
        }

        # In the reality the following case won't happen because LCM always call Test-TargetResource first before calling Set
        It "Set-TargetResource with module not found for the uninstall: Check Error" {
           
            try
            {
                # The module does not exist
                $result = MSFT_PSModule\Set-TargetResource -Name "NonExistModule" -Ensure Absent -Verbose -ErrorAction SilentlyContinue
            }
            Catch
            {
                #Expect an expection
                $_.FullyQualifiedErrorId | should be "ModuleWithRightPropertyNotFound"
                return
            } 
            
            Throw "Expected 'ModuleWithRightPropertyNotFound' exception did not happen"  
        }


        It "Set , Test-TargetResource: Check Absent and False" {

            # Calling Set-TargetResource to uninstall the MyTestModule module
            try
            {
                Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2" -Ensure "Absent" -Verbose
            }
            catch
            {
                if ($_.FullyQualifiedErrorId -ieq "ModuleWithRightPropertyNotFound")
                {
                    #The module is not installed. Ignore the error
                }
                else
                {
                    throw
                }
            }

            # Calling Get-TargetResource in the PSModule resource 
            $result = MSFT_PSModule\Test-TargetResource -Name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2"

            # Validate the result
            $result | should be $false

        }

        # Both the user's and repository installation policies are untrusted, expect an error         
        It "Set-TargetResource with Untrusted User InstallationPolicy and Source: Check Error" {
            
            # Register a repository with the untrusted policy

            RegisterRepository -Name "LocalRepository1" -InstallationPolicy Untrusted -Ensure Present -SourceLocation $LocalRepositoryPath1 -PublishLocation $LocalRepositoryPath1


            Try
            {
                # User's installation policy is untrusted.
                $result = MSFT_PSModule\Set-TargetResource -Name "MyTestModule" -Repository "LocalRepository1" -InstallationPolicy Untrusted
            }
            Catch
            {
                #Expect fail to install.
                $_.FullyQualifiedErrorId | should be "InstallationPolicyFailed"
                return
            }
            finally
            {
                  RegisterRepository -Name "LocalRepository1" -Ensure Absent -SourceLocation $LocalRepositoryPath1 -PublishLocation $LocalRepositoryPath1
            }

            Throw "Expected 'InstallationPolicyFailed' exception did not happen"           
        } 

    }#context

}#Describe



