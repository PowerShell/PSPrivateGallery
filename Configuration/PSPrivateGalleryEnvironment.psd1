@{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            Role                        = 'WebServer'
            PsDscAllowPlainTextPassword = $true

            UrlRewritePackagePath       = 'C:\PSPrivateGallery\Installers\rewrite_amd64.msi'
            SqlExpressPackagePath       = 'C:\PSPrivateGallery\Installers\SqlLocalDB_x64.msi'

            GalleryAdminCredFile        = 'C:\PSPrivateGallery\Configuration\GalleryAdminCredFile.clixml'
            GallerySourcePath           = 'C:\Program Files\WindowsPowerShell\Modules\PSGallery\GalleryContent\'

            WebsiteName                 = 'PSGallery'
            WebsitePath                 = 'C:\PSGallery'
            AppPoolName                 = 'PSGalleryAppPool'
            WebsitePort                 = 8080

            SqlInstanceName             = 'PSGallery'
            SqlDatabaseName             = 'PSGallery'
            SqlServerName               = '(LocalDB)'
        }
    )
}