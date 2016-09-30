#region enum
enum Ensure
{
    Absent
    Present
}

enum Status
{
    Exist
    NotExist
}

#endregion

#region PSGalleryModule Resource

class ModuleSpecification
{
    [DscProperty()]
    [string]$Name

    [DscProperty()]
    [string]$RequiredVersion

    [DscProperty()]
    [string]$MinimumVersion

    [DscProperty()]
    [string]$MaximumVersion
        
    [void]Validate()
    {}
}


[DscResource()]
class PSGalleryModule
{       
    [DscProperty(Key)]
    [ValidateNotNullOrEmpty()]
    [Parameter(HelpMessage = 'Name of Private PSGallery to which specified modules will be populated')]
    [string] $PrivateGalleryName
    
    [string] $PrivateGalleryLocation = ''

    [DscProperty()]
    [ValidateNotNullOrEmpty()]
    [Parameter(HelpMessage = 'Name of the Gallery where specified modules are found')]
    [string] $SourceGalleryName = 'PSGallery'

    [string] $SourceGalleryLocation = 'https://www.powershellgallery.com'

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Ensure] $Ensure
        
    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ApiKey

    [DscProperty(NotConfigurable)]
    [ModuleSpecification[]] $ModulesPresentInGallery

    [DscProperty(NotConfigurable)]
    [ModuleSpecification[]] $ModulesAbsentInGallery
        
    [DscProperty()]
    [ValidateNotNullOrEmpty()]
    [ModuleSpecification[]] $Modules
  
    [void] Set()
    {
        [PSGalleryModule]$get = $this.Get()

        if ($this.Ensure -eq 'Present')
        {  
            $this.SourceGalleryLocation = Get-SourceLocationForGallery -Name $this.SourceGalleryName
            Write-Verbose "Source Gallery Location for '$($this.SourceGalleryName)' is '$($this.SourceGalleryLocation)'"

            foreach ($module in $get.ModulesAbsentInGallery)
            {                
                Write-Verbose "'$($module.Name)' does not exist in Gallery '$($this.PrivateGalleryLocation)' and Ensure is set to '$($this.Ensure)'"                 
                Write-Verbose "Fetch '$($module.Name)' from '$($this.SourceGalleryLocation)'.."  
                
                $tempFolderLocation = Join-Path $env:Temp (get-date -uformat %s)
                mkdir $tempFolderLocation -Force
                $saveModuleParameters = Get-ModuleSpecificationParameters -Module $module
                $saveModuleParameters += @{Path = "$tempFolderLocation" ; Repository = $this.SourceGalleryName ; Force = $true ; Verbose = $true}                              
                Save-Module @saveModuleParameters
                
                $publishErrors=@()
                try
                {
                    Write-Verbose "Publish '$($module.Name)' to Gallery '$($this.PrivateGalleryLocation)'"
                    Publish-Module -Path (Join-Path $tempFolderLocation $module.Name) -NuGetApiKey $this.ApiKey -Repository $this.PrivateGalleryName -ErrorVariable publishErrors -ErrorAction SilentlyContinue
                }
                catch
                {
                    foreach ($publishError in $publishErrors)
                    {
                        Write-Warning "Error during Publish-Module - $publishError"
                    }
                }
            }
        }
        else
        {            
            foreach ($module in $get.ModulesPresentInGallery)
            {
                Write-Verbose "'$module' exists in Gallery '$($this.PrivateGalleryLocation)' and Ensure is set to '$($this.Ensure)'. Removing module '$module' from Gallery '$($this.PrivateGalleryLocation)'"

                #ToDo
                #There is no interface via front end to remove modules
                #Need to make a direct DB Call
            }
        }        
    }

    [bool] Test()
    {      

        [PSGalleryModule]$get = $this.Get()

        $count = $get.ModulesAbsentInGallery.Count        

        if ($this.Ensure -eq 'Present' -and $get.ModulesAbsentInGallery -ne $null)
        {
            Write-Verbose "Modules to be published are absent in Gallery '$($this.PrivateGalleryLocation)' and Ensure is set to '$($this.Ensure)'"                 
            return $false
        }
        elseif ($this.Ensure -eq 'Present' -and $get.ModulesAbsentInGallery -eq $null)
        {
            Write-Verbose "Modules to be published are present in Gallery '$($this.PrivateGalleryLocation)' and Ensure is set to '$($this.Ensure)'"                 
            return $true
        }
        elseif ($this.Ensure -eq 'Absent' -and $get.ModulesPresentInGallery -ne $null)
        {
            Write-Verbose "Modules to be removed are present in Gallery '$($this.PrivateGalleryLocation)' and Ensure is set to '$($this.Ensure)'"                 
            return $false
        }
        elseif ($this.Ensure -eq 'Absent' -and $get.ModulesPresentInGallery -eq $null)
        {
            Write-Verbose "Modules to be removed are absent in Gallery '$($this.PrivateGalleryLocation)' and Ensure is set to '$($this.Ensure)'"                 
            return $true
        }

        return $true        
    }

    [PSGalleryModule] Get()
    {

        $this.PrivateGalleryLocation = Get-SourceLocationForGallery -Name $this.PrivateGalleryName
        Write-Verbose "Using Gallery @ '$($this.PrivateGalleryLocation)'"
        
        # Install NuGet-anycpu.exe to avoid confirmation prompt        
        Install-NuGetBinaries
        
        foreach ($module in $($this.Modules))
        {            
            $findModuleParameters = Get-ModuleSpecificationParameters -Module $module
            $findModuleParameters += @{Repository = $this.PrivateGalleryName ; ErrorAction = 'SilentlyContinue' ; Verbose = $true}
            
            $moduleInGallery = Find-Module @findModuleParameters

            if (-not $moduleInGallery)            
            {
                Write-Verbose "'$($module.Name)' RequiredVersion='$($module.RequiredVersion)' MinimumVersion='$($module.MinimumVersion)' MaximumVersion='$($module.MaximumVersion)' does not exist in Gallery '$($this.PrivateGalleryLocation)'"                                  
                $this.ModulesAbsentInGallery += $module
            }
            else
            {
                Write-Verbose "'$($module.Name)' RequiredVersion='$($module.RequiredVersion)' MinimumVersion='$($module.MinimumVersion)' MaximumVersion='$($module.MaximumVersion)' exists in Gallery '$($this.PrivateGalleryLocation)'"
                $this.ModulesPresentInGallery += $module                
            }
        }       

        return $this
    }
}

#endregion

#region PSGalleryUser Resource

[DscResource()]
class PSGalleryUser
{    
    [DscProperty(Key)]
    [ValidateNotNullOrEmpty()]
    [string] $DatabaseInstance

    [DscProperty(Key)]
    [ValidateNotNullOrEmpty()]
    [string] $DatabaseName        
    
    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Ensure] $Ensure

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.CredentialAttribute()]
    [PSCredential] $UserCredential

    [DscProperty()]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.CredentialAttribute()]
    [PSCredential] $AdminSQLCredential

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $EmailAddress
        
    [DscProperty(Mandatory)]
    [string] $ApiKey    
        
    [DscProperty()]
    [Status] $Status = 'NotExist'    
  
    [void] Set()
    {
        [PSGalleryUser]$get = $this.Get()

        $user = Get-UserDictionary
        $userCredentials = Get-UserCredentialDictionary

        if ($this.Ensure -eq 'Present' -and $get.Status -eq 'NotExist')
        {      
            Write-Verbose "Adding user '$($user.Username)' to database '$($this.DatabaseName)'"

            #$currentDateTime = Get-Date
            #$user.CreatedUtc = $currentDateTime.ToUniversalTime()

            #Write-Verbose "Populated CreatedUtc User field to '$($user.CreatedUtc)'"
                        
            Set-TableData -TableName 'Users' -TestData $user

            # Need to update test credentials with a valid UserKey
            $UserKey = (Get-UserKey -TableName 'Users' -TestData $user)[0]
            foreach($TestCredential in $UserCredentials)
            {
                $TestCredential["UserKey"] = $UserKey
            }

            Set-TableData -TableName 'Credentials' -TestData $userCredentials
        }
        
        if ($this.Ensure -eq 'Absent' -and $get.Status -eq 'Exist')
        {
            Write-Verbose "TODO: Removing user '$($user.Username)' from database '$($this.DatabaseName)'"
        }               
    }

    [bool] Test()
    {
        [PSGalleryUser]$get = $this.Get()               

        if ($this.Ensure -eq 'Present' -and $get.Status -eq 'Exist')
        {
            Write-Verbose "User information exists in database '$($this.DatabaseName)' and Ensure is set to '$($this.Ensure)'"
            return $true
        }
        elseif ($this.Ensure -eq 'Present' -and $get.Status -eq 'NotExist')
        {
            Write-Verbose "User information does not exist in database '$($this.DatabaseName)' and Ensure is set to '$($this.Ensure)'"
            return $false
        }
        elseif ($this.Ensure -eq 'Absent' -and $get.Status -eq 'NotExist')
        {
            Write-Verbose "User information does not exist in database '$($this.DatabaseName)' and Ensure is set to '$($this.Ensure)'"
            return $true
        }
        elseif ($this.Ensure -eq 'Absent' -and $get.Status -eq 'Exist')
        {
            Write-Verbose "User information exists in database '$($this.DatabaseName)' and Ensure is set to '$($this.Ensure)'"
            return $false
        }

        return $true        
    }

    [PSGalleryUser] Get()
    {  
        #region User

        $user = Get-UserDictionary
        $userCredentials = Get-UserCredentialDictionary
        
        Write-Verbose "Get UserSettings for user '$($user.Username)'"
      
        #endregion

        
        if ((-not (Test-TableData -TableName 'Users' -TestData $user)) -or (-not (Test-TableData -TableName 'Credentials' -TestData $userCredentials)))        
        {            
            Write-Verbose "User '$($user.Username)' does not exist in database '$($this.DatabaseName)'"
            $this.Status = 'NotExist'
        }
        elseif ((Test-TableData -TableName 'Users' -TestData $user) -and (Test-TableData -TableName 'Credentials' -TestData $userCredentials))
        {
            Write-Verbose "User '$($user.Username)' exists in database '$($this.DatabaseName)'"
            $this.Status = 'Exist'
        }       

        return $this
    }
}

#endregion

#region Helpers

function Get-SourceLocationForGallery
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    Write-Verbose "Looking up SourceLocation for repository '$Name'"

    $repository = Get-PSRepository -Name $Name

    if ($repository)
    {
        Write-Verbose "SourceLocation for repository '$Name' is '$repository.SourceLocation'"
        return $repository.SourceLocation
    }

    Write-Verbose "Repository '$Name' not found"

    return $null
}

function Get-UserDictionary
    {
        $hashName = 'SHA512'
        $hashedPassword = Get-StringHash -String $($this.UserCredential).GetNetworkCredential().Password -HashName $hashName        

        $user = @{
                        'ApiKey'                           = 'NULL';
                        'EmailAddress'                     = $($this.EmailAddress);
                        'UnconfirmedEmailAddress'          = 'NULL';
                        'HashedPassword'                   = $hashedPassword;
                        'Username'                         = $($this.UserCredential).UserName;
                        'EmailAllowed'                     = 'TRUE';
                        'EmailConfirmationToken'           = 'NULL';
                        'PasswordResetToken'               = 'NULL';
                        'PasswordResetTokenExpirationDate' = 'NULL';
                        'PasswordHashAlgorithm'            = $hashName;
                        'CreatedUtc'                       = 'NULL'
        }

        $user
    }

    function Get-UserCredentialDictionary
    {

        $userCredentials = @(@{
                                'UserKey'  = '1';
                                'Type'     = 'apikey.v1';
                                'Value'    = $($this.ApiKey);
                                'Identity' = 'NULL'
                            })

        $userCredentials
    }

    function Assert
    {
        Param
        (
            [Parameter(Mandatory=$true)]
            [bool]
            $Condition,

            [Parameter(Mandatory=$true)]
            [string]
            $Message
        )

        if (-not $Condition)   
        {  
            Throw $Message
        }
    }

    function Test-TableData
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $TableName,

            [Parameter(Mandatory=$true)]        
            [hashtable[]] 
            $TestData
        )

        $result = $null
        try
        {
            $connection = New-Object System.Data.SqlClient.SqlConnection
            $connection.ConnectionString = "Server=$($this.DatabaseInstance);Initial Catalog=$($this.DatabaseName);"   #TODO
            if ($null -eq $this.AdminSQLCredential) {
		        $connection.ConnectionString += "Integrated Security=True"
	        } else {
		        $BTSR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.AdminSQLCredential.Password)
       	        $pw   = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BTSR)
		        $connection.ConnectionString += "Integrated Security=False;User Id=$($this.AdminSQLCredential.UserName);Password=$pw"
	        }          
            $connection.Open()


            # Check if the TestUser Account is created
            foreach($row in $TestData)
            {
                $command = $connection.CreateCommand()
                $command.CommandText = "SELECT * FROM [dbo].[$TableName] WHERE "
                $command.CommandText += @(foreach($key in $row.Keys)
                {
                    "[$key] = '$($row[$key])'"
                }) -join '
                 AND ' -replace " = 'NULL'", ' IS NULL'
            }

            $result = $command.ExecuteScalar()
        }
        finally
        {
            if ($connection.State -ne [System.Data.ConnectionState]::Closed)
            {
                $connection.Close()
            }
        }

        return ($result -ne $null)    
    }

    function Set-TableData
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $TableName,
        
            [Parameter(Mandatory=$true)]
            [hashtable[]]
            $TestData
        )                  

        # Check if the table is populated. If not, then populate it.
        if (-not (Test-TableData -TableName $TableName -TestData $TestData))
        {
            Write-Verbose "'$TableName' table in the database '$($this.DatabaseName)' on '$($this.DatabaseInstance)' instance is not populated. Populating the table..."

            try
            {
                Write-Verbose "Setting connection string"
                $connection = New-Object System.Data.SqlClient.SqlConnection
                $connection.ConnectionString = "Server=$($this.DatabaseInstance);Initial Catalog=$($this.DatabaseName);"   #TODO
                if ($null -eq $this.AdminSQLCredential) {
		            $connection.ConnectionString += "Integrated Security=True"
	            } else {
		            $BTSR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.AdminSQLCredential.Password)
       	            $pw   = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BTSR)
		            $connection.ConnectionString += "Integrated Security=False;User Id=$($this.AdminSQLCredential.UserName);Password=$pw"
	            }      
                $connection.Open()

                foreach($row in $TestData)
                {
                    $command = $connection.CreateCommand()

                    # Strings orgranized with newlines for output readbility during debug
                    $command.CommandText = "INSERT INTO [dbo].[$TableName]
                         ([" + ($row.Keys -join '],
                          [') + "]) 
                        VALUES
                         ('" + ($row.Values -join "',
                          '") + "')" -replace "'NULL'", 'NULL'

                    $command.ExecuteNonQuery()
                }                   
            }
            finally
            {
                if ($connection.State -ne [System.Data.ConnectionState]::Closed)
                {
                    $connection.Close()
                }
            }  

            # Check Users table again to ensure 
            Assert ((Test-TableData -TableName $TableName -TestData $TestData)) "Failed to populate '$TableName' table in the database '$($this.DatabaseName)' on '$($this.DatabaseInstance)'. Use SQL Management Studio on '$($this.DatabaseInstance)' and point to data source '$($this.DatabaseName)' to investigate further"

            Write-Verbose "The '$TableName' table in the database '$($this.DatabaseName)' on '$($this.DatabaseInstance)' instance has been populated."
        }
        else
        {
            Write-Verbose "The '$TableName' table in the database '$($this.DatabaseName)' on '$($this.DatabaseInstance)' instance is already populated."
        }
    }

    function Get-UserKey
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $TableName,
        
            [Parameter(Mandatory=$true)]
            [hashtable]
            $TestData
        ) 

        $result = @()
        try
        {
            $connection = New-Object System.Data.SqlClient.SqlConnection
            Write-Verbose "Setting connection string"
           $connection.ConnectionString = "Server=$($this.DatabaseInstance);Initial Catalog=$($this.DatabaseName);"   #TODO
            if ($null -eq $this.AdminSQLCredential) {
		        $connection.ConnectionString += "Integrated Security=True"
	        } else {
		        $BTSR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.AdminSQLCredential.Password)
       	        $pw   = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BTSR)
		        $connection.ConnectionString += "Integrated Security=False;User Id=$($this.AdminSQLCredential.UserName);Password=$pw"
	        }      
            $connection.Open()

            # Check if the TestUser Account is created
            $command = $connection.CreateCommand()
            $command.CommandText = "SELECT [Key] FROM [dbo].[$TableName] WHERE "
            $command.CommandText += @(foreach($key in $TestData.Keys)
            {
                "[$key] = '$($TestData[$key])'"
            }) -join '
                AND ' -replace " = 'NULL'", ' IS NULL'            
            $result += ($command.ExecuteScalar())
        }
        finally
        {
            if ($connection.State -ne [System.Data.ConnectionState]::Closed)
            {
                $connection.Close()
            }
        }

        return $result
    }

    function Install-NuGetBinaries
    {
        [cmdletbinding()]
        param()

        $NuGetClient = $null
        $NuGetExeName = 'NuGet.exe'
        $NuGetProviderName = 'NuGet'
        $NuGetProviderVersion  = [Version]'2.8.5.201'
        $PSGetProgramDataPath ="$env:ProgramData\Microsoft\Windows\PowerShell\PowerShellGet"
        $PSGetLocalAppDataPath="$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet"

        if($NuGetProvider -and 
           ($NuGetClient -and (Microsoft.PowerShell.Management\Test-Path -Path $NuGetClient)))
        {
            return
        }

        # Invoke Install-NuGetClientBinaries internal function in PowerShellGet module to bootstrap both NuGet provider and NuGet.exe           
        $psgetModule = Import-Module -Name PowerShellGet -PassThru -Scope Local -Verbose:$false    
        & $psgetModule Install-NuGetClientBinaries -Force -BootstrapNuGetExe -CallerPSCmdlet $PSCmdlet
        
        $NuGetProvider = PackageManagement\Get-PackageProvider -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
                                    Microsoft.PowerShell.Core\Where-Object { 
                                                                             $_.Name -eq $NuGetProviderName -and 
                                                                             $_.Version -ge $NuGetProviderVersion
                                                                           }

        $programDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $PSGetProgramDataPath -ChildPath $NuGetExeName
        $applocalDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $PSGetLocalAppDataPath -ChildPath $NuGetExeName        

        # Check if NuGet.exe is available under one of the predefined PowerShellGet locations under ProgramData or LocalAppData
        if(Microsoft.PowerShell.Management\Test-Path -Path $programDataExePath)
        {
            $NuGetClient = $programDataExePath
        }
        elseif(Microsoft.PowerShell.Management\Test-Path -Path $applocalDataExePath)
        {
            $NuGetClient = $applocalDataExePath
        }
        else
        {
            # Get the NuGet.exe location if it is available under $env:PATH
            # NuGet.exe does not work if it is under $env:WINDIR, so skipping it from the Get-Command results
            $nugetCmd = Microsoft.PowerShell.Core\Get-Command -Name $NuGetExeName `
                                                                -ErrorAction SilentlyContinue `
                                                                -WarningAction SilentlyContinue | 
                            Microsoft.PowerShell.Core\Where-Object { 
                                $_.Path -and 
                                ((Microsoft.PowerShell.Management\Split-Path -Path $_.Path -Leaf) -eq $NuGetExeName) -and
                                (-not $_.Path.StartsWith($env:windir, [System.StringComparison]::OrdinalIgnoreCase)) 
                            } | Microsoft.PowerShell.Utility\Select-Object -First 1

            if($nugetCmd -and $nugetCmd.Path)
            {
                $NuGetClient = $nugetCmd.Path
            }
        }
    }

    function Get-ModuleSpecificationParameters
    {
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [ModuleSpecification]$Module,
            
            [Switch]$ConsiderAllVersionsParameter
        )

        $moduleParameters = @{Name = $Module.Name}

        if (-not [string]::IsNullOrEmpty($Module.RequiredVersion))
        {
            Write-Verbose "'$($Module.Name)' RequiredVersion='$($Module.RequiredVersion)'"
            $moduleParameters.Add('RequiredVersion', $Module.RequiredVersion)
        }

        if (-not [string]::IsNullOrEmpty($Module.MinimumVersion))
        {
            Write-Verbose "'$($Module.Name)' MinimumVersion='$($Module.MinimumVersion)'"
            $moduleParameters.Add('MinimumVersion', $Module.MinimumVersion)
        }

        if (-not [string]::IsNullOrEmpty($Module.MaximumVersion))
        {
            Write-Verbose "'$($Module.Name)' MaximumVersion='$($Module.MaximumVersion)'"
            $moduleParameters.Add('MaximumVersion', $Module.MaximumVersion)
        }
                
        if ($Module.AllVersions -and $ConsiderAllVersionsParameter.IsPresent)
        {
            Write-Verbose "'$($Module.Name)' AllVersions='$($Module.AllVersions)'"
            $moduleParameters.Add('AllVersions', $Module.AllVersions)
        }

        return $moduleParameters
    }

    function Get-StringHash     
    { 
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string] $String,

            [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA512', 'RIPEMD160')]
            [string] $HashName = 'SHA256'
        )

        $stringBuilder = New-Object System.Text.StringBuilder 
        [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{ 
        [Void]$StringBuilder.Append($_.ToString("x2")) 
        } 
        $stringBuilder.ToString() 
    }
#endregion  