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
ConvertFrom-StringData @'
###PSLOC
    FailtoUninstall=Failed to uninstall the package '{0}'. Message: {1} 
    FailtoInstall=Failed to install the package '{0}'. Message: {1}
    PackageNotFound=Package '{0}' not found in the node
    PackageNotFoundInRepository=Package '{0}' not found in the repository. Message: {1}                
    StartGetPackage=Begin invoking get-package '{0}'
    StartFindPackage=Begin invoking find-package '{0}'
    StartInstallPackage=Begin invoking install-package '{0}' version '{1}' from '{2}' source
    StartUnInstallPackage=Begin invoking uninstall-package '{0}'
    InstalledSuccess=Successfully installed the package '{0}'
    UnInstalledSuccess=Successfully uninstalled the package '{0}'
    PackageFound=found package '{0}'
    InDesiredState=Resource '{0}' is in the desired state. Required Ensure is '{1}' and actual Ensure is '{2}'
    NotInDesiredState=Resource '{0}' is not in the desired state. Required Ensure is '{1}' and actual Ensure is '{2}'
    NotInDesiredStateVersionMismatch=Resource '{0}' is not in the desired state. Required version is '{1}' but installed is '{2}'   
    StartGetPackageSource=Begin invoking Get-packageSource '{0}'
    MultiplePackageFound=Total: '{0}' packages found with the same name. Please use 'RequiredVersion' for filtering. Message: {1}
    InstallationPolicyWarning=You are installing the module '{0}' from an untrusted repository '{1}'. Your current InstallationPolicy is '{2}'. If you trust the repository, set the policy to "Trusted". "Untrusted" otherwise. 
    InstallationPolicyFailed=Failed in the installation policy. Your current InstallationPolicy is '{0}' and the repository is '{1}'. If you trust the repository, set the policy to "Trusted". "Untrusted" otherwise.
###PSLOC

'@

