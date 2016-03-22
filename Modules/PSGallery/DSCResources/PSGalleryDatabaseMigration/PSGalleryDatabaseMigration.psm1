$galleryContentBinPath = "$PSScriptRoot\..\..\GalleryContent\bin\"

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseInstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName
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
		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseInstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName,

		[System.String]
		$ProviderName = 'System.Data.SqlClient'
	)

    # Migrate data to db using entity framework    
    $connectionString = "Server=(LocalDB)\$DatabaseInstanceName;Initial Catalog=$DatabaseName;Integrated Security=True"

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
		$DatabaseInstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName,

		[System.String]
		$ProviderName = 'System.Data.SqlClient'
	)

    Write-Verbose -Message "Connecting to Database instance $DatabaseInstanceName ..."

    # Create sql connection object
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server=(LocalDB)\$DatabaseInstanceName;Integrated Security=True"
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