$galleryContentBinPath = "$PSScriptRoot\..\..\GalleryContent\bin\"

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $false)]
		[System.String]
		$DatabaseInstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName,

		[parameter(Mandatory = $true)]
		[System.String]
		$ServerName
	)
	@{
		DatabaseInstanceName = $DatabaseInstanceName
		DatabaseName = $DatabaseName
	}
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $false)]
		[System.String]
		$DatabaseInstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName,

		[parameter(Mandatory = $true)]
		[System.String]
		$ServerName,

		[System.String]
		$ProviderName = 'System.Data.SqlClient'
	)

    # Migrate data to db using entity framework
	if ([string]::IsNullOrEmpty($DatabaseInstanceName)) {
		$connectionString = "Server=$ServerName;Initial Catalog=$DatabaseName;Integrated Security=True"
	} else {
		$connectionString = "Server=$ServerName\$DatabaseInstanceName;Initial Catalog=$DatabaseName;Integrated Security=True"
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
		[parameter(Mandatory = $false)]
		[System.String]
		$DatabaseInstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName,

		[parameter(Mandatory = $true)]
		[System.String]
		$ServerName,

		[System.String]
		$ProviderName = 'System.Data.SqlClient'
	)

    Write-Verbose -Message "Connecting to Database instance $DatabaseInstanceName ..."

    # Create sql connection object
    $connection = New-Object System.Data.SqlClient.SqlConnection
	if ([string]::IsNullOrEmpty($DatabaseInstanceName)) {
		$connection.ConnectionString = "Server=$ServerName;Integrated Security=True"
	} else {
		$connection.ConnectionString = "Server=$ServerName\$DatabaseInstanceName;Integrated Security=True"
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