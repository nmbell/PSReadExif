function Get-ExifType
{
	<#
	.SYNOPSIS
	Internal function.

	.DESCRIPTION
	Generates a dictionary of data types.

	.EXAMPLE
	Get-ExifType

	.NOTES
	Author : nmbell
	#>

	# Function alias
	# [Alias('xxx')]

	# Use cmdlet binding
	[CmdletBinding()]

	# Declare parameters
	Param()

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
		$typeDataCsv = Get-Content -Path $script:dataTypesPath | ConvertFrom-Csv

		# Create a list of types
		$typesHashTable = @{}
		ForEach ($td in $typeDataCsv)
		{
			$typesHashTable[[Int16]$td.NumericValue.Trim()] = $td.Description.Trim()
		}

		# Output
		$typesHashTable
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
