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

# Calling the setup function 
SetupNugetTest

Describe -Name "NugetPackage Integration Test" -Tags "RI" {


    BeforeEach {

    }

    AfterEach {

    }

    It "Start-DSC, Get-Dscconfiguration: Check Present" {
        
       # Compile the sample configuration to MOF and run Start-DscConfiguration
       $module=Get-Module -Name "PackageManagementProviderResource" -ListAvailable
       & "$($module.ModuleBase)\Examples\Sample_NuGet_InstallPackage.ps1"

        $getResult = Get-DscConfiguration 

        # Validate the returned results
        $getResult[0].Ensure | should be "Present"
        $getResult[0].Name | should be "Mynuget"
        $getResult[0].ProviderName | should be "Nuget"
        $getResult[0].SourceUri | should be "http://nuget.org/api/v2/"
        $getResult[0].InstallationPolicy | should be "Trusted"

        $getResult[1].Ensure | should be "Present"
        $getResult[1].Name | should be "Jquery.2.0.1"
        $getResult[1].InstalledVersion | should be "2.0.1"
        $getResult[1].SoftwareIdentity | should not BeNullOrEmpty

        # Check if the module exists. Source here is the installed path
        
        Test-Path $getResult[1].Source | should be $true

        # Calling Test to validate if it is true
        $testResult = Test-DscConfiguration
            
        $testResult | should be $true
    }

}


