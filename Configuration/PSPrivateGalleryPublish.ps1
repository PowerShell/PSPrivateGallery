Configuration PSPrivateGalleryPublish
{
    Import-DscResource -ModuleName PSGallery
    Import-DscResource -ModuleName PackageManagementProviderResource -ModuleVersion 1.0.3

    Node $AllNodes.Where{$_.Role -eq 'Gallery'}.Nodename
    {    
        # Obtain credential for Gallery operations
        $GalleryAppPoolCredential = (Import-Clixml $Node.GalleryAdminCredFile)
        $GalleryUserCredential    = (Import-Clixml $Node.GalleryUserCredFile)

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
            DatabaseInstance      = "$($Node.SQLServerName)\$($Node.SQLInstanceName)"
            DatabaseName          = $Node.SQLDatabaseName
            Ensure                = 'Present'
            UserCredential        = $GalleryUserCredential
            #AdminSQLCredential    = $GalleryAppPoolCredential
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