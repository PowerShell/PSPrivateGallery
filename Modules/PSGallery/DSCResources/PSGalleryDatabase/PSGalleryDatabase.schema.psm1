Configuration PSGalleryDataBase
{
 param
    (
        # Location to the MSI setup file for SQL Express package
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $SqlExpressPackagePath,        

        # Credential for Gallery setup
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.CredentialAttribute()]
        [PSCredential] $DatabaseAdminCredential,

        # Sql Instance Name
        [ValidateNotNullOrEmpty()]
        [String] $SqlInstanceName = 'PSGallery',

        # Name of Sql Database       
        [ValidateNotNullOrEmpty()]
        [String] $SqlDatabaseName = 'PSGallery'
        
        
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration    
    Import-DscResource -ModuleName SQLExpress   

    # Install SQL Express
    Package SQLExpress
    {
        Ensure    = 'Present'
        Path      = $SqlExpressPackagePath
        Name      = 'Microsoft SQL Server 2014 Express LocalDB '
        ProductId = '' #'AB8DE9BA-19E1-446A-BCFA-6B3DA9751E21'
        Arguments = 'IACCEPTSQLLOCALDBLICENSETERMS=YES'        
    }

    <#

    # Create RunAs User for WebAppPool
    User GalleryAdmin
    {
        Ensure    = 'Present'
        UserName  = $DatabaseAdminCredential.UserName
        Password  = $DatabaseAdminCredential
    }

    #>
    
    # Create SQLExpress Instance
    SQLExpressInstance SQLInstance
    {
        Ensure               = 'Present'
        InstanceName         = $SqlInstanceName
        Status               = 'Running'
        PsDscRunAsCredential = $DatabaseAdminCredential
        DependsOn            = '[Package]SQLExpress'
    }
    
    # Create SQExpress Database
    SQLExpressDatabase SQLDataBase
    {
        InstanceName         = $SqlInstanceName
        Name                 = $SqlDatabaseName
        Ensure               = 'Present'
        PsDscRunAsCredential = $DatabaseAdminCredential
        DependsOn            = '[SQLExpressInstance]SQLInstance'
    }
}