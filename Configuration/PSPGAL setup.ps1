dir –Path “C:\PSPrivateGallery” –Recurse | Unblock-File
Copy-Item –Path “C:\PSPrivateGallery\Modules\*” –Destination “C:\Program Files\WindowsPowerShell\Modules” –Recurse -Force
Cd “C:\PSPrivateGallery\Configuration”
Get-Credential –Credential GalleryUser  | Export-Clixml .\GalleryUserCredFile.clixml
Get-Credential –Credential GalleryAdmin | Export-Clixml .\GalleryAdminCredFile.clixml
.\PSPrivateGallery.ps1