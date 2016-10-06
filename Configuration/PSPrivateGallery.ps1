[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = 'ApplyOnly'
            ActionAfterReboot = 'ContinueConfiguration'
        }
    }
}

Configuration PSPrivateGallery
{
    Import-DscResource -Module PSGallery
    Import-DscResource -Module xWebAdministration -ModuleVersion 1.9.0.0

    Node $AllNodes.Where{$_.Role -eq 'WebServer'}.Nodename
    {
        # Obtain credential for Gallery setup operations
        $GalleryCredential = (Import-Clixml $Node.GalleryAdminCredFile)

        # Setup and Configure Web Server
        PSGalleryWebServer GalleryWebServer
        {
            UrlRewritePackagePath = $Node.UrlRewritePackagePath
            AppPoolCredential     = $GalleryCredential
            GallerySourcePath     = $Node.GallerySourcePath
            WebSiteName           = $Node.WebsiteName
            WebsitePath           = $Node.WebsitePath
            WebsitePort           = $Node.WebsitePort
            AppPoolName           = $Node.AppPoolName
        }

        #Setup and Configure SQL Express
        PSGalleryDataBase GalleryDataBase
        {
            SqlExpressPackagePath    = $Node.SqlExpressPackagePath
            DatabaseAdminCredential  = $GalleryCredential
            SqlInstanceName          = $Node.SqlInstanceName
            SqlDatabaseName          = $Node.SqlDatabaseName
        }
        

        # Migrate entity framework schema to SQL DataBase
        # This is agnostic to the type of SQL install - SQL Express/Full SQL
        # Hence a separate resource
        PSGalleryDatabaseMigration GalleryDataBaseMigration
        {
            DatabaseInstanceName = "$($Node.SqlServerName)\$($Node.SqlInstanceName)"
            DatabaseName         = $Node.SqlDatabaseName
            PsDscRunAsCredential = $GalleryCredential
            #SQLLoginCredential   = $GalleryCredential      # Leave out if localDB
            DependsOn           = '[PSGalleryDataBase]GalleryDataBase'
        }

        # Make the connection between Gallery Web Server and Database instance
        xWebConnectionString SQLConnection
        {
            Ensure           = 'Present'
            Name             = 'Gallery.SqlServer'
            WebSite          = $Node.WebsiteName
            DatabaseInstanceName = "$($Node.SqlServerName)\$($Node.SqlInstanceName)"
            DatabaseName         = $Node.SqlDatabaseName
            #SQLLoginCredential = $GalleryCredential        # Leave out if localDB
            DependsOn        = '[PSGalleryWebServer]GalleryWebServer','[PSGalleryDataBaseMigration]GalleryDataBaseMigration'
        }
    }
}


LCMConfig
Set-DscLocalConfigurationManager -Path .\LCMConfig -Force -Verbose -ComputerName localhost

PSPrivateGallery -ConfigurationData .\PSPrivateGalleryEnvironment.psd1
Start-DscConfiguration -Path .\PSPrivateGallery -Wait -Force -Verbose