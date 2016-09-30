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
    StartGetPackageSource=Begin invoking Get-packageSource {0}
    StartRegisterPackageSource=Begin invoking Register-Packagesource {0}
    StartUnRegisterPackageSource=Begin invoking UnRegister-Packagesource {0}
    PackageSourceFound=Package source '{0}' found
    PackageSourceNotFound=Package source '{0}' not found
    RegisteredSuccess=Successfully registered the package source {0}
    UnRegisteredSuccess=Successfully unregistered the package source {0}
    RegisterFailed=Failed to register the package source {0}. Message:{1}
    UnRegisterFailed=Failed to register the package source {0}. Message:{1}
    InDesiredState=Resource {0} is in the desired state. Required Ensure is {1} and actual Ensure is {2}
    NotInDesiredState=Resource {0} is not in the desired state. Required Ensure is {1} and actual Ensure is {2}
    NotInDesiredStateDuetoLocationMismatch=Resource {0} is not in the desired state. Required location is {1} and registered is {2}
    NotInDesiredStateDuetoPolicyMismatch=Resource {0} is not in the desired state. Required installation policy is {1} and registered is {2}
    InstallationPolicyWarning=Begin registering '{0}' to source location '{1}' with '{2}' policy"
###PSLOC

'@

