function Add-ExifData
{
	<#
	.SYNOPSIS
	Adds EXIF data from an image file to the file properties.

	.DESCRIPTION
	Adds EXIF data from an image file to the file properties.
	Tags known to the [System.Drawing.Bitmap] class are decoded with the corresponding tag name.
	To see a list of known tags, use Get-ExifTag.
	Unknown tags may also be retrieved.
	Some selected tags are used to create artifical tags that have a PS object for the data returned, e.g. DateTimePS is created from the DateTime tag.
	Any file can be passed to the function, but EXIF data will not be included for files that do not have recognizable EXIF data.

	.PARAMETER Path
	Path to the image file.

	.PARAMETER TagId
	List of tag ids to be included.
	TagIds can be entered as either decimals, hex values, or strings.
	Wildcard characters are supported for string values.

	.PARAMETER NoPSData
	Exclude artificial data (additional data for selected tags as PS objects).

	.PARAMETER ShowUnknown
	Include unknown data points in the output.

	.EXAMPLE
	## Add all known EXIF data to the file object ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-Item -Path $Path | Add-ExifData | Select-Object -ExpandProperty ExifData

	.EXAMPLE
	## Add all known EXIF data for a file, suppressing artificial data ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-Item -Path $Path | Add-ExifData -NoPSData | Select-Object -ExpandProperty ExifData

	.EXAMPLE
	## Add EXIF data for specific tags for a file ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-Item -Path $Path | Add-ExifData -TagId 271,'272',0x11A,([Int32]'0x11B'),Orientation,'*ISO*' | Select-Object -ExpandProperty ExifData

	.EXAMPLE
	## Add all known and unknown EXIF data for a file ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-Item -Path $Path | Add-ExifData -ShowUnknown | Select-Object -ExpandProperty ExifData

	.EXAMPLE
	## Add EXIF data for a specific tag for all files in a directory, including the file name in the output ##

	PS C:\> $Path = 'C:\my\images'
	PS C:\> Get-ChildItem -Path $Path -PipelineVariable pv | Add-ExifData -TagId DateTimePS | Select-Object -ExpandProperty ExifData | Format-Table @{n='File';e={$pv.Name}},Key,Value

	.NOTES
	Author : nmbell

	.LINK
	https://docs.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-constant-property-item-descriptions
	#>

	# Function alias
	# [Alias('xxx')]

	# Use cmdlet binding
	[CmdletBinding()]

	# Declare parameters
	Param
	(

		[Parameter(
		  Mandatory                       = $true
		, Position                        = 0
		, ValueFromPipeline               = $true
		, ValueFromPipelineByPropertyName = $true
		)]
		[String]
		$Path

	,	[Alias('Id')]
		[String[]]
		$TagId = @('*')

	,	[Switch]
		$NoPSData

	,	[Switch]
		$ShowUnknown

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
		If ($TagId) { $TagId += '-1' } # always get the file object

		# Gather EXIF data
		$exifData = Get-ExifData -Path $Path -TagId $TagId -NoPSData:$NoPSData -ShowUnknown:$ShowUnknown

		# Accumulate EXIF as properties
		$exifDataProperty = $null
		$file             = $null
		If ($exifData)
		{
			$exifDataProperty = @{}
			ForEach ($e in $exifData)
			{
				If ($e.IdDec -eq -1) # artificial file object tag
				{
					$file = $e.ValueDecoded
				}
				Else
				{
					$exifDataProperty[$e.Tag] = $e.ValueDisplay
				}
			}
		}

		# Output
		$file | Add-Member -MemberType NoteProperty -Name ExifData -Value $exifDataProperty -Force -PassThru
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
