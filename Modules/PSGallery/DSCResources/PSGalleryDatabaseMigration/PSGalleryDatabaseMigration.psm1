$galleryContentBinPath = "$PSScriptRoot\..\..\GalleryContent\bin\"

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
        	[ValidateNotNullOrEmpty()]
		$DatabaseInstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName,

       		[parameter(Mandatory = $false)]
		[PSCredential]
		$SQLLoginCredential
	)
	@{
		DatabaseInstanceName = $DatabaseInstanceName
		DatabaseName = $DatabaseName
       		SQLLoginCredential = $SQLLoginCredential
	}
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
        	[ValidateNotNullOrEmpty()]
		$DatabaseInstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName,

		[parameter(Mandatory = $false)]
		[PSCredential]
		$SQLLoginCredential,

		[System.String]
		$ProviderName = 'System.Data.SqlClient'
	)

    # Migrate data to db using entity framework
	$connectionString = [String]::Empty
	$connectionString += "Server=$DatabaseInstanceName;Initial Catalog=$DatabaseName;"

	if ($null -eq $SQLLoginCredential) {
		$connectionString += "Integrated Security=True"
	} else {
		$BTSR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SQLLoginCredential.Password)
       	$pw   = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BTSR)
		$connectionString += "Integrated Security=False;User Id=$($SQLLoginCredential.UserName);Password=$pw"
	}

    Write-Verbose -Message "Creating tables etc. in database $DatabaseName ..."
    Push-Location $galleryContentBinPath
    .\migrate.exe NuGetGallery.dll /connectionString="$connectionString" /connectionProviderName="$ProviderName" /verbose
    Pop-Location
    Write-Verbose -Message "Database $DatabaseName is now correctly configured"
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
        	[ValidateNotNullOrEmpty()]
		$DatabaseInstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName,

        	[parameter(Mandatory = $false)]
		[PSCredential]
		$SQLLoginCredential,

		[System.String]
		$ProviderName = 'System.Data.SqlClient'
	)

    Write-Verbose -Message "Connecting to Database instance $DatabaseInstanceName ..."

    # Create sql connection object
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server=$DatabaseInstanceName;"

    if ($null -eq $SQLLoginCredential) {
		$connection.ConnectionString += "Integrated Security=True"
	} else {
		$BTSR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SQLLoginCredential.Password)
       	$pw   = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BTSR)
		$connection.ConnectionString += "Integrated Security=False;User Id=$($SQLLoginCredential.UserName);Password=$pw"
	}
    $connection.Open()

    # Create sql command
    Write-Verbose -Message "Checking if database $DatabaseName is correctly configured ..."
    $Command = $Connection.CreateCommand()
    $Command.CommandText = "SELECT Name FROM [$DatabaseName].[dbo].[Roles]"
    $commandResult = try{$Command.ExecuteScalar()}catch{}

    # Close the sql connection
    if($connection.State -ne [System.Data.ConnectionState]::Closed){$connection.Close()}

    # Execute the command and check if the database has been initialized
    if($commandResult -ne 'Admins')
    {
        Write-Verbose -Message "Database $DatabaseName is not correctly configured"
        return $false
    }
    else
    {
        Write-Verbose -Message "Database $DatabaseName is correctly configured"
        return $true
    }
}

Export-ModuleMember -Function *-TargetResource