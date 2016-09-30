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
# Pre-Requisite: MyTestModule 1.1, 1.1.2, 3.2.1 are available under the $LocalRepositoryPath for testing purpose only.
# It's been taken care of by SetupPSModuleTest
#

# Calling the setup function 
SetupPSModuleTest

Describe -Name  "PSModule Get-TargetResource Basic Tests" -Tags "BVT" {

    BeforeEach {

        # Remove all left over files if exists
        Remove-Item "$($InstallationFolder)\..\..\MyTestModule" -Recurse -Force  -ErrorAction SilentlyContinue      
        Remove-Item "$($InstallationFolder)\..\MyTestModule" -Recurse -Force  -ErrorAction SilentlyContinue      
    }

    AfterEach {

    }     


    # Register a local module repository to make the test run faster. This gets called once per Describe. 
    RegisterRepository -Name "LocalRepository" -InstallationPolicy Trusted -Ensure Present

    It "Get-TargetResource with the Mandatory Parameters: Check Present" {            
            
            # Calling Set-TargetResource to install the MyTestModule
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "3.2.1" -Ensure "Present" -Verbose

            # Calling Get-TargetResource in the PSModule resource 
            $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository $LocalRepository 

            # Validate the result
            $result.Ensure | should be "Present"
        }

    It -Skip "Get-TargetResource given the different versions of modules on the same repository: Check Present" {            
           
            #Calling Set-TargetResource to install the module
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "3.2.1" -Ensure "Present" -Verbose
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2" -Ensure "Present" -Verbose
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1" -Ensure "Present" -Verbose

            $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository $LocalRepository 

            #Validate the returned results. You can also use "Get-Module -ListAvailable -name MyTestModule" to find these info
            $result.Ensure | should be "Present"
            $result.Name | should be "MyTestModule"
            $result.Repository | should be $LocalRepository
            $result.InstalledVersion | should be "3.2.1"
            $result.InstallationPolicy | should be "Trusted"
            ($result.Author.Length -ne 0)  | should be $true 
            $result.ModuleType | should be "Manifest"
            $result.ModuleBase.StartsWith($InstallationFolder ) | should be $true         
            ($result.Description.Length -ne 0)  | should be $true  
        }

    It "Get-TargetResource with RequiredVersion: Check Present" {
            
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2" -Ensure "Present" -Verbose

            # Provide a req version that exists, expect ensure=Present
            $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2"

            #Validate the returned results
            $result.Ensure | should be "Present"
            $result.Name | should be "MyTestModule"
            $result.InstalledVersion | should be "1.1.2"    
        }

    It "Get-TargetResource with Non-exist RequiredVersion: Check Absent" {
            
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository  -RequiredVersion "1.1.2" -Ensure "Present" -Verbose

            #Provide a req version does not exist, expect Ensure=Absent
            $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository $LocalRepository -RequiredVersion "10.11.12"

            #Validate the returned results
            $result.Ensure | should be "Absent"  
        }

    It -Skip "Get-TargetResource with MaximumVersion: Check Present" {
            
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "3.2.1" -Ensure "Present" -Verbose
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1" -Ensure "Present" -Verbose
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2" -Ensure "Present" -Verbose

            $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository $LocalRepository  -MaximumVersion "2.0"
                
            $result.Ensure | should be "Present"         
            $result.InstalledVersion | should be "1.1.2"  #1.1.2 is the only module -le maximumversion 
        }

    It -Skip "Get-TargetResource MinimumVersion: Check Present" {
            
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2" -Ensure "Present" -Verbose
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1"   -Ensure "Present" -Verbose
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "3.2.1" -Ensure "Present" -Verbose

            $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository $LocalRepository  -MinimumVersion "1.1.1"

            $result.Ensure | should be "Present"
            $result.InstalledVersion | should be "3.2.1"  #Here two modules: 1.1.1 and 3.2.1 are qualified. Get-Target will return the latest
        }

    It -Skip "Get-TargetResource MinimumVersion and MaximumVersion: Check Present" {
            
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2" -Ensure "Present" -Verbose
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1" -Ensure "Present" -Verbose
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "3.2.1" -Ensure "Present" -Verbose

            $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository $LocalRepository  -MinimumVersion "1.0"  -MaximumVersion "2.0"

            $result.Ensure | should be "Present"
            $result.InstalledVersion | should be "1.1.2"  
        }
        
}#Describe

Describe -Name "PSModule Get-TargetResource Error Cases" -Tags "RI" {

    BeforeEach {

        #Remove all left over files if exists
        Remove-Item "$($InstallationFolder)\..\..\MyTestModule" -Recurse -Force  -ErrorAction SilentlyContinue      
        Remove-Item "$($InstallationFolder)\..\MyTestModule" -Recurse -Force  -ErrorAction SilentlyContinue      
    }

    AfterEach {

    }

    #Register a local module repository to make the test run faster. This gets called once per Describe.
    RegisterRepository -Name "LocalRepository" -InstallationPolicy Trusted -Ensure Present

    # Not allow Max, Req and Min co-existance 
    It "Get-TargetResource with Max, Req and Min Verion: Check Absent" {
      
        Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2" -Ensure "Present" -Verbose

        $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository $LocalRepository  `
                                        -MinimumVersion "1.0" -RequiredVersion "1.1.1" #-MaximumVersion "2.3.5"                                     
       
        # Get-Target does not throw, so check 'Absent' is enough here
        $result.Ensure | should be "Absent"
    }
    
    # Min should le Max 
    It "Get-TargetResource with Max le Min Verion: Check Absent" {

      
            Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2" -Ensure "Present" -Verbose
            
            $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository $LocalRepository  `
                                         -MinimumVersion "5.0" #-MaximumVersion "2.5"                                    

           $result.Ensure | should be "Absent"                
    }

    It "Get-TargetResource with NoneExistRepository: Check Absent" {

        Set-TargetResource -name "MyTestModule" -Repository $LocalRepository -RequiredVersion "1.1.2" -Ensure "Present" -Verbose
            
        $result = MSFT_PSModule\Get-TargetResource -Name "MyTestModule" -Repository "NoneExistRepository"  `
                                        -MinimumVersion "1.0" # -MaximumVersion "2.5"

        $result.Ensure | should be "Absent"
    }
}
