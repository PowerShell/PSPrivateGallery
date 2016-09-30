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
    StartGetPackage=Begin invoking Get-package {0} using PSModulePath {1}.
    PackageFound=Package '{0}' found.
    PackageNotFound=Package '{0}' not found.
    MultiplePackagesFound=More than one package found for package '{0}'.
    StartTestPackage=Test-TargetResource calling Get-TargetResource using {0}.
    InDesiredState=Resource {0} is in the desired state. Required Ensure is {1} and actual Ensure is {2}
    NotInDesiredState=Resource {0} is not in the desired state. Required Ensure is {1} and actual Ensure is {2}
    StartSetPackage=Set-TargetResource calling Test-TargetResource using {0}.
    InstallPackageInSet=Calling Install-Package using {0}.
###PSLOC

'@

