# [Project is in Preview mode]
# Deploy and Manage a Private PowerShell Gallery


### Prerequisites:
- Windows 10 / Windows OS containing WMF 5.1 [https://msdn.microsoft.com/en-us/powershell/wmf/5.1/install-configure]


### Steps
- Clone this project locally OR Use the files from [Releases](https://github.com/PowerShell/PSPrivateGallery/releases) section.
- Deploy Gallery DSC Resources ``$env:PSModulePath``
    - Copy ``~\Modules`` folder contents to ``$env:ProgramFiles\WindowsPowerShell\Modules``
- Generate Credential files - ``~\Configuration\GalleryAdminCredFile.clixml``, ``~\Configuration\GalleryUserCredFile.clixml``
    - `Get-Credential –Credential GalleryUser  | Export-Clixml .\GalleryUserCredFile.clixml `
    - `Get-Credential –Credential GalleryAdmin | Export-Clixml .\GalleryAdminCredFile.clixml `
- Update Configuration Data for your needs
    - ``~\Configuration\PSPrivateGalleryEnvironment.psd1``
    - ``~\Configuration\PSPrivateGalleryPublishEnvironment.psd1``
- Deploy the Gallery
    - ``~\Configuration\PSPrivateGallery.ps1``
- Populate the local instance of the Gallery with specified PowerShell modules
    - ``~\Configuration\PSPrivateGalleryPublish.ps1``

 - Add inbound firewall rule permitting access to the gallery
   - `New-NetFirewallRule -Name PSGallery -DisplayName "PSGallery" -Description "Allow access to the PSGallery" -Protocol TCP -RemoteAddress Any -LocalPort 8080 -Action Allow -enabled True  `

 - Register the Private PSGallery as an internal PowerShell repository, using Register-PSRepository.
    - `Register-PSRepository –Name PSPrivateGallery –SourceLocation “http://localhost:8080/api/v2” –InstallationPolicy Trusted –PackageManagementProvider NuGet `

- Discovery, Installation and Inventory of module using the internal/private PowerShell repository
    - `Find-Module –Name PSScriptAnalyzer `
    - `Install-Module –Name PSScriptAnalyzer `
    - `Get-Module –Name PSScriptAnalyzer `

