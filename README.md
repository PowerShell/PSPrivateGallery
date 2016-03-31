# [Project is in Preview mode]
# Deploy and Manage a Private PowerShell Gallery


### Prerequisites:
- Windows 10 / Windows OS containing WMF 5.0 RTM [https://www.microsoft.com/en-us/download/details.aspx?id=50395]


### Steps
- Clone this project locally
- Deploy Gallery DSC Resources ``$env:PSModulePath`` - Copy ``~\Modules`` folder contents to ``$env:ProgramFiles\WindowsPowerShell\Modules``
- Generate Credential files - ``~\Configuration\GalleryAdminCredFile.clixml``, ``~\Configuration\GalleryUserCredFile.clixml``
- Update Configuration Data for your needs - ``~\Configuration\PSPrivateGalleryEnvironment.psd1``, ``~\Configuration\PSPrivateGalleryPublishEnvironment.psd1``
- Deploy the Gallery ``~\Configuration\PSPrivateGallery.ps1``
- Populate the local instance of the Gallery with specified PowerShell modules ``~\Configuration\PSPrivateGalleryPublish.ps1``
