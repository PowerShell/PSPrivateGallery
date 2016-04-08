Configuration PSPrivateGalleryPublish
{
    Import-DscResource -ModuleName PSGallery
    Import-DscResource -ModuleName PackageManagementProviderResource
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 3.8.0.0

    Node $AllNodes.Where{$_.Role -eq 'Gallery'}.Nodename
    {    
        # Obtain credential for Gallery operations
        $GalleryAppPoolCredential = (Import-Clixml $Node.GalleryAdminCredFile)
        $GalleryUserCredential    = (Import-Clixml $Node.GalleryUserCredFile)
        
        # Sql binary temp folder
        File SqlFolder {
            Ensure = 'Present'
            DestinationPath = $(Split-Path -Path $Node.SqlExpressPackagePath -Parent)
            Type = 'Directory'
        }
        
        # Download SQL express 2014
        xRemoteFile SQLexpressUri {
            Uri = 'https://download.microsoft.com/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/LocalDB%2064BIT/SqlLocalDB.msi'    
            DestinationPath = $Node.SqlExpressPackagePath
            UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer
            Headers = @{"Accept-Language" = "en-US"}
            MatchSource = $false
            DependsOn = '[File]SqlFolder'
        }
        
        # UrlRewrite module binary temp folder
        File UrlRewriteFolder {
            Ensure = 'Present'
            DestinationPath = $(Split-Path -Path $Node.UrlRewritePackagePath -Parent)
            Type = 'Directory'
        }
        
        # Download UrlRewrite module
        xRemoteFile UrlRewriteUri {
            Uri = 'https://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi'    
            DestinationPath = $Node.UrlRewritePackagePath
            UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer
            Headers = @{"Accept-Language" = "en-US"}
            MatchSource = $false
            DependsOn = '[File]UrlRewriteFolder'
        }
        
        # Source Gallery where the specified modules will be present
        PackageManagementSource SourceGallery
        {
            Name                 = $Node.SourceGalleryName
            ProviderName         = 'PowerShellGet'
            SourceUri            = $Node.SourceGalleryLocation
            PsDscRunAsCredential = $GalleryAppPoolCredential
            Ensure               = 'Present'
            InstallationPolicy   = 'Trusted'
        }

        # Destination Gallery to publish the specified modules
        PackageManagementSource PrivateGallery
        {
            Name                 = $Node.PrivateGalleryName
            ProviderName         = 'PowerShellGet'
            SourceUri            = $Node.PrivateGalleryLocation
            PsDscRunAsCredential = $GalleryAppPoolCredential
            Ensure               = 'Present'
            InstallationPolicy   = 'Trusted'
        }
        
        # Local Gallery User
        PSGalleryUser PrivateGalleryUser
        {
            DatabaseInstance      = $Node.SQLInstance
            DatabaseName          = $Node.DatabaseName
            Ensure                =  'Present'
            UserCredential        = $GalleryUserCredential
            PsDscRunAsCredential  = $GalleryAppPoolCredential
            EmailAddress          = $Node.EmailAddress
            ApiKey                = $Node.ApiKey
        }
        
        # Publish specified modules from Source Gallery to Destinations Gallerys
        PSGalleryModule PrivateGalleryModule
        {   
            Ensure                      = 'Present'

            SourceGalleryName           = $Node.SourceGalleryName                       
            PrivateGalleryName          = $Node.PrivateGalleryName
                        
            PsDscRunAsCredential        = $GalleryAppPoolCredential

            ApiKey                      = $Node.ApiKey

            Modules                     = $Node.Modules | % {
                                                        ModuleSpecification
                                                        {
                                                            Name = $_.ModuleName
                                                            RequiredVersion = $_.RequiredVersion
                                                            MinimumVersion = $_.MinimumVersion
                                                            MaximumVersion = $_.MaximumVersion
                                                        }
                                            }

            DependsOn                   = '[PackageManagementSource]SourceGallery','[PackageManagementSource]PrivateGallery','[PSGalleryUser]PrivateGalleryUser'
        }
    }
}

PSPrivateGalleryPublish -ConfigurationData .\PSPrivateGalleryPublishEnvironment.psd1

Start-DscConfiguration -Path .\PSPrivateGalleryPublish -Wait -Force -Verbose