Configuration PSGalleryWebServer
{
    param
    (
        # Location to the MSI setup file for UrlRewrite package
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $UrlRewritePackagePath,

        # List of Windows features to add for webserver role        
        [ValidateNotNullOrEmpty()]
        [String[]] $WindowsFeaturesToAdd = @('Web-Http-Tracing'
                                            'Web-Request-Monitor'
                                            'Web-Windows-Auth'
                                            'Web-Static-Content'
                                            'Web-Asp-Net45'
                                            'Web-IP-Security'
                                            'Web-Mgmt-Service'
                                            'Web-Mgmt-Console'
                                            ),

        # Credential for Gallery setup
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.CredentialAttribute()]
        [PSCredential] $AppPoolCredential,

        # Web App Pool name for Gallery website
        [ValidateNotNullOrEmpty()]
        [String] $AppPoolName = 'PSGalleryAppPool',

        # Location of Source files for setting up the Gallery
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $GallerySourcePath,

        # Website name for the Gallery        
        [ValidateNotNullOrEmpty()]
        [String] $WebSiteName = 'PSGallery',

        # Website local path for the Gallery        
        [ValidateNotNullOrEmpty()]
        [String] $WebSitePath = 'c:\PSGallery',

        # Website port for the Gallery        
        [ValidateNotNullOrEmpty()]
        [String] $WebSitePort = '8080'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration    

    # Install necessary windows features
    Foreach ($feature in $WindowsFeaturesToAdd)
    {
        WindowsFeature $feature
        {
            Ensure = 'Present'
            Name   = $feature
        }
    }

    # Install URL Rewrite
    Package URLRewrite
    {
        Ensure    = 'Present'
        Path      = $UrlRewritePackagePath
        Name      = 'IIS URL Rewrite Module 2'
        ProductId = '' #'EB675D0A-2C95-405B-BEE8-B42A65D23E11'
    }

    # Create RunAs User for WebAppPool
    User GalleryAdmin
    {
        Ensure    = 'Present'
        UserName  = $AppPoolCredential.UserName
        Password  = $AppPoolCredential      
    }

    # Create webapp pool
    xWebAppPool GalleryAppPool
    {
        Ensure             = 'Present'
        Name               = $AppPoolName
        State              = 'Started'
        identityType       = 'SpecificUser'
        Credential         = $AppPoolCredential
        DependsOn          = '[User]GalleryAdmin'
    }
        
    # Copy the Gallery conent
    File GalleryContent
    {
        Ensure          = 'Present'
        SourcePath      = $GallerySourcePath
        DestinationPath = $WebSitePath
        Recurse         = $true
        Type            = 'Directory'
        DependsOn       = '[xWebAppPool]GalleryAppPool'
    }

    # Create the website
    xWebsite GalleryWebSite
    {
        Ensure          = 'Present'
        Name            = $WebsiteName
        PhysicalPath    = $WebSitePath
        State           = 'Started'
        ApplicationPool = $AppPoolName
        BindingInfo     = MSFT_xWebBindingInformation
                            {
                                Protocol = 'http'
                                Port = $WebSitePort
                            }
        DependsOn       = '[File]GalleryContent'
    }
}