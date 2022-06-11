function Get-ExifTag
{
	<#
	.SYNOPSIS
	Returns a list of tags known to the [System.Drawing.Bitmap] class.

	.DESCRIPTION
	Returns a list of tags known to the [System.Drawing.Bitmap] class.

	.PARAMETER AsHashTable
	Returns data as a hash table.

	.EXAMPLE
	## Get all known EXIF tags ##

	PS C:\> Get-ExifTag

	.EXAMPLE
	## Get all known EXIF tags as a hash table ##

	PS C:\> Get-ExifTag -AsHashTable

	.NOTES
	Author : nmbell

	.LINK
	https://docs.microsoft.com/en-us/dotnet/api/system.drawing.imaging.propertyitem.id?view=dotnet-plat-ext-6.0
	#>

	# Function alias
	# [Alias('xxx')]

	# Use cmdlet binding
	[CmdletBinding()]

	# Declare parameters
	Param
	(

		[Switch]
		$AsHashTable

	)

	BEGIN
	{
		# Common BEGIN:
		Set-StrictMode -Version 3.0
		$start            = Get-Date
		$thisFunctionName = $MyInvocation.MyCommand
		Write-Verbose "[$thisFunctionName]Started: $($start.ToString('yyyy-MM-dd HH:mm:ss.fff'))"

		# Function BEGIN:
	}

	PROCESS
	{
		# Read from file
		$tagDataCsv = Get-Content -Path $script:tagDescriptionsPath | ConvertFrom-Csv

		# Create a list of tags
		If ($AsHashTable)
		{
			$tagHashTable = @{}
			ForEach ($td in $tagDataCsv)
			{
				$tagHashTable[[Int32]$td.IdDec] = $td.Tag
			}

			# Output
			$tagHashTable
		}
		Else
		{
			# Output
			$tagDataCsv
		}
	}

	END
	{
		# Function END:

		# Common END:
		$end      = Get-Date
		$duration = New-TimeSpan -Start $start -End $end
		Write-Verbose "[$thisFunctionName]Stopped: $($end.ToString('yyyy-MM-dd HH:mm:ss.fff')) ($($duration.ToString('d\d\ hh\:mm\:ss\.fff')))"
	}
}
