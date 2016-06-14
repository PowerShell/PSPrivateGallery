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
    Import-DscResource -Module xWebAdministration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 3.8.0.0
    
    Node $AllNodes.Where{$_.Role -eq 'WebServer'}.Nodename
    {
        # Obtain credential for Gallery setup operations
        $GalleryCredential = (Import-Clixml $Node.GalleryAdminCredFile)
        
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
        
        # Setup and Configure SQL Express
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
            DatabaseInstanceName = $Node.SqlInstanceName
            DatabaseName         = $Node.SqlDatabaseName
            PsDscRunAsCredential = $GalleryCredential
            DependsOn            = '[PSGalleryDataBase]GalleryDataBase'
        }        

        # Make the connection between Gallery Web Server and Database instance        
        xWebConnectionString SQLConnection
        {
            Ensure           = 'Present'
            Name             = 'Gallery.SqlServer'
            WebSite          = $Node.WebsiteName
            ConnectionString = "Server=(LocalDB)\$($Node.SqlInstanceName);Initial Catalog=$($Node.SqlDatabaseName);Integrated Security=True"
            DependsOn        = '[PSGalleryWebServer]GalleryWebServer','[PSGalleryDataBaseMigration]GalleryDataBaseMigration'
        }                
    }
}


LCMConfig
Set-DscLocalConfigurationManager -Path .\LCMConfig -Force -Verbose -ComputerName localhost

PSPrivateGallery -ConfigurationData .\PSPrivateGalleryEnvironment.psd1
Start-DscConfiguration -Path .\PSPrivateGallery -Wait -Force -Verbose