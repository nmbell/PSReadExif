function Get-ExifData
{
	<#
	.SYNOPSIS
	Retrieves EXIF data from an image file.

	.DESCRIPTION
	Retrieves EXIF data from an image file.
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
	## Get all known EXIF data for a file ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-ExifData -Path $Path

	.EXAMPLE
	## Get all artifical tag data for a file ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-ExifData -Path $Path -TagId *PS

	.EXAMPLE
	## Get all known EXIF data for a file, suppressing artificial data ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-ExifData -Path $Path -NoPSData

	.EXAMPLE
	## Get all known EXIF data for a file using the pipeline ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-Item -Path $Path | Get-ExifData

	.EXAMPLE
	## Get EXIF data for specific tags for a file ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-ExifData -Path $Path -TagId 271,'272',0x11A,([Int32]'0x11B'),Orientation,'*ISO*'

	.EXAMPLE
	## Get all known and unknown EXIF data for a file ##

	PS C:\> $Path = 'C:\my\images\Canon.jpg'
	PS C:\> Get-ExifData -Path $Path -ShowUnknown

	.EXAMPLE
	## Get all known EXIF data for all files in a directory using the pipeline ##

	PS C:\> $Path = 'C:\my\images'
	PS C:\> Get-ChildItem -Path $Path | Get-ExifData

	.EXAMPLE
	## Get EXIF data for a specific tag for all files in a directory, including the file name in the output ##

	PS C:\> $Path = 'C:\my\images'
	PS C:\> Get-ChildItem -Path $Path -PipelineVariable pv | Get-ExifData -TagId DateTimePS | Format-Table @{n='File';e={$pv.Name}},Tag,ValueDisplay

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
		$TagId

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
		Write-Verbose "[$thisFunctionName]Inspecting $Path"

		# Create a bitmap object from the image file
		Try
		{
			$bitmap = [System.Drawing.Bitmap]::new($Path)
		}
		Catch
		{
			$bitmap = $null
		}

		# Output an artificial tag for the file object
		If ((!$TagId -and !$NoPSData ) -or ($TagId -and ('-1' -in $TagId -or '[System.IO.FileInfo]' -in $TagId)))
		{
			$file = Get-Item -Path $Path -Force
			If (!$file)
			{
				$file = Get-Item -LiteralPath $Path -Force
			}

			If ($file)
			{
				[PSCustomObject]@{
					PSTypeName   = 'PSReadExif'
					IdDec        = -1
					IdHex        = '0xFFFF'
					Tag          = '[System.IO.FileInfo]'
					Type         = 2
					TypeDesc     = 'UNDEFINED'
					Length       = $file.Length
					ValueBytes   = $null
					ValueDecoded = $file
					ValueDisplay = $file
				}
			}
		}

		# Parse the EXIF data
		If ($bitmap)
		{
			ForEach ($propItem in $bitmap.PropertyItems)
			{
				Try
				{
					$idDec        = $propItem.Id          # Int32
					$idHex        = '0x{0:X}' -f $idDec
					$tag          = $script:tags[$idDec]
					$type         = $propItem.Type        # Int16
					$typeDesc     = $script:types[$type]
					$length       = $propItem.Len         # Int32
					$valueBytes   = $propItem.Value       # Byte[]
					$valueDecoded = @()
					$valueDisplay = $null
					$d            = $null
					$n            = $null
					# $h            = ''

					If ($ShowUnknown)
					{
						$tag = ($tag ?? "Unknown_$idHex`_$($idDec.ToString())")
					}

					If ($TagId)
					{
						$tagMatch = $null
						ForEach ($t in $TagId)
						{
							If ([Int32]::TryParse($t,[ref]$null) -and ([Int32]$t -eq $idDec)) { $tagMatch = $idDec        }
							If ($tag -like ($t.ToString() -replace 'PS([?*])?$','')         ) { $tagMatch = $t.ToString() }
						}
						If (!$tagMatch) { Continue }
						Write-Debug "  [$thisFunctionName]Matched tag: $tagMatch"
					}

					If (!$tag) { Continue }

					Write-Debug "  [$thisFunctionName]$($idDec.ToString())|$idHex|$tag|$($type.ToString())|$typeDesc|$($length.ToString())|$($valueBytes.ToString())"

					If ($type -eq 1) # BYTE
					{
						$valueDecoded = $valueBytes
					}

					If ($type -eq 2) # ASCII
					{
						$ascii        = [System.Text.ASCIIEncoding]::new()
						$valueDecoded += $ascii.GetString($valueBytes[0..$($valueBytes.Length-2)]) # trim off the trailing [Char]0 (null terminator)
						$valueDisplay = $valueDecoded[0]
					}

					If ($type -eq 3) # SHORT (UInt16)
					{
						For ($i = 0; $i -lt $valueBytes.Length; $i += 2)
						{
							$valueDecoded += [System.BitConverter]::ToUInt16($valueBytes,$i)
						}
					}

					If ($type -eq 4) # LONG (UInt32)
					{
						For ($i = 0; $i -lt $valueBytes.Length; $i += 4)
						{
							$valueDecoded += [System.BitConverter]::ToUInt32($valueBytes,$i)
						}
					}

					If ($type -eq 5) # RATIONAL (UInt32/UInt32)
					{
						Write-Debug "  [$thisFunctionName]$($idDec.ToString())|$idHex|$tag|$valueBytes"
						For ($i = 0; $i -lt $valueBytes.Length; $i += 4)
						{
							If ($null -eq $n)
							{
								$n = [System.BitConverter]::ToUInt32($valueBytes,$i)
							}
							ElseIf ($null -ne $n)
							{
								$d = [System.BitConverter]::ToUInt32($valueBytes,$i)
							}
							If ($d -and $null -ne $n)
							{
								Write-Debug "  [$thisFunctionName]$($idDec.ToString())|$idHex|$tag|`$n = $($n.ToString())|`$d = $($d.ToString())"
								$valueDecoded += ($n/$d)
								$n = $d = $null
							}
						}
					}

					# If ($type -eq 6) # n/a

					If ($type -eq 7) # UNDEFINED
					{
						$ascii        = [System.Text.ASCIIEncoding]::new() # could be anything, so let's try our luck with ASCII
						$valueDecoded += $ascii.GetString($valueBytes)
						$valueDisplay = $valueDecoded[0]
					}

					# If ($type -eq 8) # n/a

					If ($type -eq 9) # SLONG (Int32)
					{
						For ($i = 0; $i -lt $valueBytes.Length; $i += 4)
						{
							$valueDecoded += [System.BitConverter]::ToInt32($valueBytes,$i)
						}
					}

					If ($type -eq 10) # SRATIONAL (Int32/Int32)
					{
						Write-Debug "  [$thisFunctionName]$($idDec.ToString())|$idHex|$tag|$valueBytes"
						For ($i = 0; $i -lt $valueBytes.Length; $i += 4)
						{
							If ($null -eq $n)
							{
								$n = [System.BitConverter]::ToInt32($valueBytes,$i)
							}
							ElseIf ($null -ne $n)
							{
								$d = [System.BitConverter]::ToInt32($valueBytes,$i)
							}
							If ($d -and $null -ne $n)
							{
								Write-Debug "  [$thisFunctionName]$($idDec.ToString())|$idHex|$tag|`$n = $($n.ToString())|`$d = $($d.ToString())"
								$valueDecoded += ($n/$d)
								$n = $d = $null
							}
						}
					}

					# Interpret decoded values
					Switch ($idDec)
					{
						{
							$_ -in
							259,	# 0x0103	Compression
							20515	# 0x5023	ThumbnailCompression
						}
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1	    { 'Uncompressed'                                                 ; Break }
								2	    { 'CCITT 1D'                                                     ; Break }
								3	    { 'T4/Group 3 Fax'                                               ; Break }
								4	    { 'T6/Group 4 Fax'                                               ; Break }
								5	    { 'LZW'                                                          ; Break }
								6	    { 'JPEG (old-style)'                                             ; Break }
								7	    { 'JPEG'                                                         ; Break }
								8	    { 'Adobe Deflate'                                                ; Break }
								9	    { 'JBIG B&W'                                                     ; Break }
								10	    { 'JBIG Color'                                                   ; Break }
								99	    { 'JPEG'                                                         ; Break }
								262	    { 'Kodak 262'                                                    ; Break }
								32766	{ 'Next'                                                         ; Break }
								32767	{ 'Sony ARW Compressed'                                          ; Break }
								32769	{ 'Packed RAW'                                                   ; Break }
								32770	{ 'Samsung SRW Compressed'                                       ; Break }
								32771	{ 'CCIRLEW'                                                      ; Break }
								32772	{ 'Samsung SRW Compressed 2'                                     ; Break }
								32773	{ 'PackBits'                                                     ; Break }
								32809	{ 'Thunderscan'                                                  ; Break }
								32867	{ 'Kodak KDC Compressed'                                         ; Break }
								32895	{ 'IT8CTPAD'                                                     ; Break }
								32896	{ 'IT8LW'                                                        ; Break }
								32897	{ 'IT8MP'                                                        ; Break }
								32898	{ 'IT8BL'                                                        ; Break }
								32908	{ 'PixarFilm'                                                    ; Break }
								32909	{ 'PixarLog'                                                     ; Break }
								32946	{ 'Deflate'                                                      ; Break }
								32947	{ 'DCS'                                                          ; Break }
								33003	{ 'Aperio JPEG 2000 YCbCr'                                       ; Break }
								33005	{ 'Aperio JPEG 2000 RGB'                                         ; Break }
								34661	{ 'JBIG'                                                         ; Break }
								34676	{ 'SGILog'                                                       ; Break }
								34677	{ 'SGILog24'                                                     ; Break }
								34712	{ 'JPEG 2000'                                                    ; Break }
								34713	{ 'Nikon NEF Compressed'                                         ; Break }
								34715	{ 'JBIG2 TIFF FX'                                                ; Break }
								34718	{ 'Microsoft Document Imaging (MDI) Binary Level Codec'          ; Break }
								34719	{ 'Microsoft Document Imaging (MDI) Progressive Transform Codec' ; Break }
								34720	{ 'Microsoft Document Imaging (MDI) Vector'                      ; Break }
								34887	{ 'ESRI Lerc'                                                    ; Break }
								34892	{ 'Lossy JPEG'                                                   ; Break }
								34925	{ 'LZMA2'                                                        ; Break }
								34926	{ 'Zstd'                                                         ; Break }
								34927	{ 'WebP'                                                         ; Break }
								34933	{ 'PNG'                                                          ; Break }
								34934	{ 'JPEG XR'                                                      ; Break }
								65000	{ 'Kodak DCR Compressed'                                         ; Break }
								65535	{ 'Pentax PEF Compressed'                                        ; Break }
								Default { $valueDecoded[0].ToString()                                    ; Break }
							}
							Break
						}

						{
							$_ -in
							33432,	# 0x8298	Copyright
							20539	# 0x503B	ThumbnailCopyRight
						}
						{
							$valueDisplay = ($valueDisplay -split [Char]0 | Where-Object { $_.Trim() })
							Break
						}

						{
							$_ -in
							37378,	# 0x9202	ExifAperture
							37381	# 0x9205	ExifMaxAperture
						}
						{
							$valueDisplay = 'f/{0:f1}' -f [Math]::Pow(2,$valueDecoded[0]/2)
							Break
						}

						37379		# 0x9203	ExifBrightness
						{
							$numerator = [System.BitConverter]::ToInt32($valueBytes[0..3],0)
							$valueDisplay = Switch ($numerator)
							{
								-1      { 'Unknown'        ; Break }
								Default { $valueDecoded[0] ; Break }
							}
							Break
						}

						41730		# 0xA302	ExifCfaPattern
						{
							$cfaLookup = @{
								0 = 'RED'
								1 = 'GREEN'
								2 = 'BLUE'
								3 = 'CYAN'
								4 = 'MAGENTA'
								5 = 'YELLOW'
								6 = 'WHITE'
							}

							$across = [System.BitConverter]::ToInt16($valueBytes[1..0],0)
							# $down   = [System.BitConverter]::ToInt16($valueBytes[3..2],0)

							$valueDisplay = @()
							$row          = ''
							ForEach ($b in $valueBytes[4..($valueBytes.Length-1)])
							{
								$row += $cfaLookup[[Int]$b][0]
								If (($row.Length%$across) -eq 0)
								{
									$valueDisplay += $row
									$row = ''
								}
							}
							Break
						}

						40961		# 0xA001	ExifColorSpace
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0       { 'Unknown'                   ; Break }
								1       { 'sRGB'                      ; Break }
								2       { 'Adobe RGB'                 ; Break }
								65533   { 'Wide Gamut RGB'            ; Break }
								65534   { 'ICC Profile'               ; Break }
								65535   { 'Uncalibrated'              ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						37121		# 0x9101	ExifCompConfig
						{
							$valueDecoded = $valueBytes | ForEach-Object { [Int32]$_ }
							$valueDisplay = ($valueDecoded | ForEach-Object {
								Switch ($_)
								{
									0       { ''            ; Break }
									1       { 'Y'           ; Break }
									2       { 'Cb'          ; Break }
									3       { 'Cr'          ; Break }
									4       { 'R'           ; Break }
									5       { 'G'           ; Break }
									6       { 'B'           ; Break }
									Default { $_.ToString() ; Break }
								}
							}) -join ''
							Break
						}

						34850		# 0x8822	ExifExposureProg
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0       { 'Not Defined'               ; Break }
								1       { 'Manual'                    ; Break }
								2       { 'Program AE'                ; Break }
								3       { 'Aperture-priority AE'      ; Break }
								4       { 'Shutter speed priority AE' ; Break }
								5       { 'Creative (Slow speed)'     ; Break }
								6       { 'Action (High speed)'       ; Break }
								7       { 'Portrait'                  ; Break }
								8       { 'Landscape'                 ; Break }
								9       { 'Bulb'                      ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						33434		# 0x829A	ExifExposureTime
						{
							# $reciprocal = [Int](1/$valueDecoded[0])
							# $valueDisplay = $valueDecoded[0] -lt 1.0 ? '1/{0} sec' -f [Int](1/$valueDecoded[0]) : $valueDecoded[0]
							If ($valueDecoded[0] -lt 1.0)
							{
								$valueDisplay = '1/{0} sec' -f [Int](1/$valueDecoded[0])
							}
							Else
							{
								$valueDisplay = '{0} sec' -f $valueDecoded[0]
							}
							Break
						}

						41728		# 0xA300	ExifFileSource
						{
							$valueDecoded = $valueBytes
							$sigma        = $valueBytes.Count -eq 4 ? 'Sigma ' : ''
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0       { 'Unknown'                   ; Break }
								1       { 'Film scanner'              ; Break }
								2       { 'Reflection print scanner'  ; Break }
								3       { "$sigma`Digital camera"     ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						37385		# 0x9209	ExifFlash
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0	    { 'No Flash'                                            ; Break }
								1	    { 'Fired'                                               ; Break }
								5	    { 'Fired, Return not detected'                          ; Break }
								7	    { 'Fired, Return detected'                              ; Break }
								8	    { 'On, Did not fire'                                    ; Break }
								9	    { 'On, Fired'                                           ; Break }
								13	    { 'On, Return not detected'                             ; Break }
								15	    { 'On, Return detected'                                 ; Break }
								16	    { 'Off, Did not fire'                                   ; Break }
								20	    { 'Off, Did not fire, Return not detected'              ; Break }
								24	    { 'Auto, Did not fire'                                  ; Break }
								25	    { 'Auto, Fired'                                         ; Break }
								29	    { 'Auto, Fired, Return not detected'                    ; Break }
								31	    { 'Auto, Fired, Return detected'                        ; Break }
								32	    { 'No flash function'                                   ; Break }
								48	    { 'Off, No flash function'                              ; Break }
								65	    { 'Fired, Red-eye reduction'                            ; Break }
								69	    { 'Fired, Red-eye reduction, Return not detected'       ; Break }
								71	    { 'Fired, Red-eye reduction, Return detected'           ; Break }
								73	    { 'On, Red-eye reduction'                               ; Break }
								77	    { 'On, Red-eye reduction, Return not detected'          ; Break }
								79	    { 'On, Red-eye reduction, Return detected'              ; Break }
								80	    { 'Off, Red-eye reduction'                              ; Break }
								88	    { 'Auto, Did not fire, Red-eye reduction'               ; Break }
								89	    { 'Auto, Fired, Red-eye reduction'                      ; Break }
								93	    { 'Auto, Fired, Red-eye reduction, Return not detected' ; Break }
								95	    { 'Auto, Fired, Red-eye reduction, Return detected'     ; Break }
								Default { $valueDecoded[0].ToString()                           ; Break }
							}
							Break
						}

						33437		# 0x829D	ExifFNumber
						{
							$format = $valueDecoded[0] -lt 1.0 ? 'f/{0:F2}' : 'f/{0:F1}'
							$valueDisplay = $format -f $valueDecoded[0]
							Break
						}

						37386		# 0x920A	ExifFocalLength
						{
							$valueDisplay = '{0}mm' -f $valueDecoded[0]
							Break
						}

						34855		# 0x8827	ExifISOSpeed
						{
							$valueDisplay = 'ISO {0}'                       -f $valueDecoded[0]
							Break
						}

						37384		# 0x9208	ExifLightSource
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0	    { 'Unknown'                   ; Break }
								1	    { 'Daylight'                  ; Break }
								2	    { 'Fluorescent'               ; Break }
								3	    { 'Tungsten (Incandescent)'   ; Break }
								4	    { 'Flash'                     ; Break }
								9	    { 'Fine Weather'              ; Break }
								10	    { 'Cloudy'                    ; Break }
								11	    { 'Shade'                     ; Break }
								12	    { 'Daylight Fluorescent'      ; Break }
								13	    { 'Day White Fluorescent'     ; Break }
								14	    { 'Cool White Fluorescent'    ; Break }
								15	    { 'White Fluorescent'         ; Break }
								16	    { 'Warm White Fluorescent'    ; Break }
								17	    { 'Standard Light A'          ; Break }
								18	    { 'Standard Light B'          ; Break }
								19	    { 'Standard Light C'          ; Break }
								20	    { 'D55'                       ; Break }
								21	    { 'D65'                       ; Break }
								22	    { 'D75'                       ; Break }
								23	    { 'D50'                       ; Break }
								24	    { 'ISO Studio Tungsten'       ; Break }
								255	    { 'Other'                     ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						37500		# 0x927C	ExifMakerNote
						{
							$valueDecoded = $null
							$valueDisplay = $null
							Break
						}

						37383		# 0x9207	ExifMeteringMode
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0       { 'Unknown'                   ; Break }
								1       { 'Average'                   ; Break }
								2       { 'Center-weighted average'   ; Break }
								3       { 'Spot'                      ; Break }
								4       { 'Multi-spot'                ; Break }
								5       { 'Multi-segment'             ; Break }
								6       { 'Partial'                   ; Break }
								255     { 'Other'                     ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						41729		# 0xA301	ExifSceneType
						{
							$valueDecoded = $valueBytes
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0       { 'Unknown'                   ; Break }
								1       { 'Directly photographed'     ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						41495		# 0xA217	ExifSensingMethod
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'Not defined'               ; Break }
								2       { 'One-chip color area'       ; Break }
								3       { 'Two-chip color area'       ; Break }
								4       { 'Three-chip color area'     ; Break }
								5       { 'Color sequential area'     ; Break }
								7       { 'Trilinear'                 ; Break }
								8       { 'Color sequential linear'   ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						37377	# 0x9201	ExifShutterSpeed
						{
							If ($valueDecoded[0] -lt 0)
							{
								$valueDisplay = '0 sec'
							}
							Else
							{
								$valueDisplay = '1/{0} sec' -f [Int](1/[Math]::Pow(2,$valueDecoded[0]*-1))
							}
							Break
						}

						37382		# 0x9206	ExifSubjectDist
						{
							If ($valueBytes[0] -eq '0x0')
							{
								$valueDisplay = 'Unknown'
							}
							ElseIf ($valueBytes[0] -eq '0xFFFFFFFF')
							{
								$valueDisplay = 'Infinity'
							}
							Else
							{
								$valueDisplay = "{0}m" -f $valueDecoded[0]
							}
							Break
						}

						# 37510		# 0x9286	ExifUserComment
						# {
						# }

						{
							$_ -in
							36864,	# 0x9000	ExifVer
							40960	# 0xA000	ExifFPXVer
						}
						{
							If (![Int32]::TryParse($valueDisplay,[ref]$null))
							{
								$valueDecoded = $valueBytes
								$valueDisplay = $valueBytes
							}
							Break
						}

						338			# 0x0152	ExtraSamples
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0       { 'Unspecified'               ; Break }
								1       { 'Associated Alpha'          ; Break }
								2       { 'Unassociated Alpha'        ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						266			# 0x010A	FillOrder
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'Normal'                    ; Break }
								2       { 'Reversed'                  ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						6			# 0x0006	GPSAltitude
						{
							$valueDisplay = "{0}m" -f $valueDecoded[0]
							Break
						}

						5			# 0x0005	GPSAltitudeRef
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0       { 'Above sea level'           ; Break }
								1       { 'Below sea level'           ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						23			# 0x0017	GpsDestBearRef
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								'M'     { 'Magnetic North'            ; Break }
								'T'     { 'True North'                ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						25			# 0x0019	GpsDestDistRef
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								'K'     { 'Kilometers'                ; Break }
								'M'     { 'Miles'                     ; Break }
								'N'     { 'Nautical Miles'            ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						{
							$_ -in
							20,		# 0x0014	GpsDestLat
							22		# 0x0016	GpsDestLong
						}
						{
							$valueDisplay = "{0:d3}° {1:d2}' {2:00.0000}`"" -f $valueDecoded[0],$valueDecoded[1],$valueDecoded[2]
							Break
						}

						10			# 0x000A	GpsGpsMeasureMode
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								'2'     { '2-Dimensional Measurement' ; Break }
								'3'     { '3-Dimensional Measurement' ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						9			# 0x0009	GpsGpsStatus
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								'A'     { 'Measurement Active'        ; Break }
								'V'     { 'Measurement Void'          ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						7			# 0x0007	GpsGpsTime
						{
							$valueDisplay = "{0:d2}:{1:d2}:{2:f3}+0" -f $valueDecoded[0],$valueDecoded[1],$valueDecoded[2]
							Break
						}

						16			# 0x0010	GpsImgDirRef
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								'M'     { 'Magnetic North'            ; Break }
								'T'     { 'True North'                ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						{
							$_ -in
							2,		# 0x0002	GPSLatitude
							4		# 0x0004	GPSLongitude
						}
						{
							If ($valueDecoded[1].GetType().FullName -eq 'System.Double' -and $valueDecoded[2] -eq 0)
							{
								$valueDecoded[2] = [Int]($valueDecoded[1]%1)*60
								$valueDecoded[1] = [Int]$valueDecoded[1]
							}
							$valueDisplay = "{0:d3}° {1:d2}' {2:00.0000}`"" -f $valueDecoded[0],$valueDecoded[1],$valueDecoded[2]
							Break
						}

						12			# 0x000C	GPSSpeedRef
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								'K'     { 'kph'                       ; Break }
								'M'     { 'mph'                       ; Break }
								'N'     { 'knots'                     ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						14			# 0x000E	GPSTrackRef
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								'M'     { 'Magnetic North'            ; Break }
								'T'     { 'True North'                ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						0			# 0x0000	GpsVer
						{
							$valueDecoded = $valueBytes -join '.'
							$valueDisplay = $valueDecoded
						}

						290			# 0x0122	GrayResponseUnit
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 0.1                         ; Break }
								2       { 0.001                       ; Break }
								3       { 0.0001                      ; Break }
								4       { 1e-05                       ; Break }
								5       { 1e-06                       ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						332			# 0x014C	InkSet
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'CMYK'                      ; Break }
								2       { 'Not CMYK'                  ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						512			# 0x0200	JPEGProc
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'Baseline'                  ; Break }
								14      { 'Lossless'                  ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						254			# 0x00FE	NewSubfileType
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								-1      { 'Invalid'                                                  ; Break }
								0       { 'Full-resolution image'                                    ; Break }
								1       { 'Reduced-resolution image'                                 ; Break }
								2       { 'Single page of multi-page image'                          ; Break }
								3       { 'Single page of multi-page reduced-resolution image'       ; Break }
								4       { 'Transparency mask'                                        ; Break }
								5       { 'Transparency mask of reduced-resolution image'            ; Break }
								6       { 'Transparency mask of multi-page image'                    ; Break }
								7       { 'Transparency mask of reduced-resolution multi-page image' ; Break }
								8       { 'Depth map'                                                ; Break }
								9       { 'Depth map of reduced-resolution image'                    ; Break }
								10      { 'Enhanced image data'                                      ; Break }
								65537   { 'Alternate reduced-resolution image'                       ; Break }
								65540   { 'Semantic Mask'                                            ; Break }
								Default { $valueDecoded[0].ToString()                                ; Break }
							}
							Break
						}

						{
							$_ -in
							274,	# 0x0112	Orientation
							20521	# 0x5029	ThumbnailOrientation
						}
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'Horizontal (normal) (top left)'                     ; Break }
								2       { 'Mirror horizontal (top right)'                      ; Break }
								3       { 'Rotate 180° (bottom right)'                         ; Break }
								4       { 'Mirror vertical (bottom left)'                      ; Break }
								5       { 'Mirror horizontal and rotate 270° CW (left top)'    ; Break }
								6       { 'Rotate 90° CW (right top)'                          ; Break }
								7       { 'Mirror horizontal and rotate 90° CW (right bottom)' ; Break }
								8       { 'Rotate 270° CW (left bottom)'                       ; Break }
								Default { $valueDecoded[0].ToString()                          ; Break }
							}
							Break
						}

						262			# 0x0106	PhotometricInterp
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								0       { 'WhiteIsZero'               ; Break }
								1       { 'BlackIsZero'               ; Break }
								2       { 'RGB'                       ; Break }
								3       { 'RGB Palette'               ; Break }
								4       { 'Transparency Mask'         ; Break }
								5       { 'CMYK'                      ; Break }
								6       { 'YCbCr'                     ; Break }
								8       { 'CIELab'                    ; Break }
								9       { 'ICCLab'                    ; Break }
								10      { 'ITULab'                    ; Break }
								32803   { 'Color Filter Array'        ; Break }
								32844   { 'Pixar LogL'                ; Break }
								32845   { 'Pixar LogLuv'              ; Break }
								32892   { 'Sequential Color Filter'   ; Break }
								34892   { 'Linear Raw'                ; Break }
								51177   { 'Depth Map'                 ; Break }
								52527   { 'Semantic Mask'             ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						284			# 0x011C	PlanarConfig
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'Chunky'                    ; Break }
								2       { 'Planar'                    ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						317			# 0x013D	Predictor
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'None'                      ; Break }
								2       { 'Horizontal differencing'   ; Break }
								3       { 'Floating point'            ; Break }
								34892   { 'Horizontal difference X2'  ; Break }
								34893   { 'Horizontal difference X4'  ; Break }
								34894   { 'Floating point X2'         ; Break }
								34895   { 'Floating point X4'         ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						{
							$_ -in
							296,	# 0x0128	ResolutionUnit
							41488,	# 0xA210	ExifFocalResUnit
							20528	# 0x5030	ThumbnailResolutionUnit
						}
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'None'                      ; Break }
								2       { 'inches'                    ; Break }
								3       { 'cm'                        ; Break }
								4       { 'mm'                        ; Break }
								5       { 'μm'                        ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						339			# 0x0153	SampleFormat
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'Unsigned'                  ; Break }
								2       { 'Signed'                    ; Break }
								3       { 'Float'                     ; Break }
								4       { 'Undefined'                 ; Break }
								5       { 'Complex int'               ; Break }
								6       { 'Complex float'             ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						255			# 0x00FF	SubfileType
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'Full-resolution image'           ; Break }
								2       { 'Reduced-resolution image'        ; Break }
								3       { 'Single page of multi-page image' ; Break }
								Default { $valueDecoded[0].ToString()       ; Break }
							}
							Break
						}

						292			# 0x0124	T4Option
						{
							$bit0 = ($valueDecoded[0] -band 1) -shr 0
							$bit1 = ($valueDecoded[0] -band 2) -shr 1
							$bit2 = ($valueDecoded[0] -band 4) -shr 2

							$valueDisplay = @()
							If ($bit0) { $valueDisplay += '2-Dimensional encoding' }
							If ($bit1) { $valueDisplay += 'Uncompressed'           }
							If ($bit2) { $valueDisplay += 'Fill bits added'        }
							Break
						}

						293			# 0x0125	T6Option
						{
							$bit0 = ($valueDecoded[0] -band 1) -shr 0

							$valueDisplay = @()
							If ($bit0) { $valueDisplay += 'Uncompressed' }
							Break
						}

						263			# 0x0107	ThreshHolding
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'No dithering or halftoning' ; Break }
								2       { 'Ordered dither or halftone' ; Break }
								3       { 'Randomized dither'          ; Break }
								Default { $valueDecoded[0].ToString()  ; Break }
							}
							Break
						}

						{
							$_ -in
							531,	# 0x0213	YCbCrPositioning
							20537	# 0x5039	ThumbnailYCbCrPositioning
						}
						{
							$valueDisplay = Switch ($valueDecoded[0])
							{
								1       { 'Centered'                  ; Break }
								2       { 'Co-sited'                  ; Break }
								Default { $valueDecoded[0].ToString() ; Break }
							}
							Break
						}

						{
							$_ -in
							530,	# 0x0212	YCbCrSubSampling
							20536	# 0x5038	ThumbnailYCbCrSubsampling
						}
						{
							$valueDisplay = Switch ($valueDecoded[0,1] -join ',')
							{
								'1,1'   { 'YCbCr4:4:4'                    ; Break }
								'1,2'   { 'YCbCr4:4:0'                    ; Break }
								'1,4'   { 'YCbCr4:4:1'                    ; Break }
								'2,1'   { 'YCbCr4:2:2'                    ; Break }
								'2,2'   { 'YCbCr4:2:0'                    ; Break }
								'2,4'   { 'YCbCr4:2:1'                    ; Break }
								'4,1'   { 'YCbCr4:1:1'                    ; Break }
								'4,2'   { 'YCbCr4:1:0'                    ; Break }
								Default { $($valueDecoded[0,1] -join ',') ; Break }
							}
							Break
						}

						Default
						{
							$valueDisplay = ${valueDecoded}?.Count -eq 0 ? $null : ${valueDecoded}?.Count -eq 1 ? $valueDecoded[0] : $valueDecoded
						}
					}
					Write-Debug "  [$thisFunctionName]$($idDec.ToString())|$idHex|$tag|$valueDecoded|$valueDisplay"

					# Output
					If ($valueDecoded -and ($valueDecoded | Get-Member -MemberType Method -Name Trim))
					{
						$valueDecoded = $valueDecoded.Trim()
					}
					If ($valueDisplay -and ($valueDisplay | Get-Member -MemberType Method -Name Trim))
					{
						$valueDisplay = $valueDisplay.Trim()
					}

					If (!$TagId -or ($TagId -and $idDec -eq $tagMatch -or $tag -like $tagMatch))
					{
						[PSCustomObject]@{
							PSTypeName   = 'PSReadExif'
							IdDec        = $idDec
							IdHex        = $idHex
							Tag          = $tag
							Type         = $type
							TypeDesc     = $typeDesc
							Length       = $length
							ValueBytes   = $valueBytes
							ValueDecoded = $valueDecoded
							ValueDisplay = $valueDisplay
						}
					}

					# Create some artifical tags for ease of use
					If (!$NoPSData)
					{
						If ($tag -in 'ImageWidth','PixelXDimension')
						{
							If (!$TagId -or ($TagId -and $idDec -eq $tagMatch -or 'ImageWidthPS' -like $tagMatch))
							{
								[PSCustomObject]@{
									PSTypeName   = 'PSReadExif'
									IdDec        = $idDec
									IdHex        = $idHex
									Tag          = 'ImageWidthPS'
									Type         = $type
									TypeDesc     = $typeDesc
									Length       = $length
									ValueBytes   = $valueBytes
									ValueDecoded = $valueDecoded
									ValueDisplay = $valueDisplay
								}
							}
						}

						If ($tag -in 'ImageLength','PixelYDimension')
						{
							If (!$TagId -or ($TagId -and $idDec -eq $tagMatch -or 'ImageHeightPS' -like $tagMatch))
							{
								[PSCustomObject]@{
									PSTypeName   = 'PSReadExif'
									IdDec        = $idDec
									IdHex        = $idHex
									Tag          = 'ImageHeightPS'
									Type         = $type
									TypeDesc     = $typeDesc
									Length       = $length
									ValueBytes   = $valueBytes
									ValueDecoded = $valueDecoded
									ValueDisplay = $valueDisplay
								}
							}
						}

						If (!$TagId -or ($TagId -and $idDec -eq $tagMatch -or ($tag+'PS') -like $tagMatch))
						{
							If ($valueDisplay -match '^\d{4}:\d{2}:\d{2} \d{2}:\d{2}:\d{2}$') # datetime tags
							{
								$dt = $valueDecoded -split '[: ]'
								$psDateTime = Get-Date -Year $dt[0] -Month $dt[1] -Day $dt[2] -Hour $dt[3] -Minute $dt[4] -Second $dt[5]

								[PSCustomObject]@{
									PSTypeName   = 'PSReadExif'
									IdDec        = $idDec
									IdHex        = $idHex
									Tag          = ($tag+'PS')
									Type         = $type
									TypeDesc     = $typeDesc
									Length       = $length
									ValueBytes   = $valueBytes
									ValueDecoded = $psDateTime
									ValueDisplay = $psDateTime
								}
							}

							If ($tag -eq 'GpsGpsTime')
							{
								$psTime = New-TimeSpan -Hours $valueDecoded[0] -Minutes $valueDecoded[1] -Seconds $valueDecoded[2]

								[PSCustomObject]@{
									PSTypeName   = 'PSReadExif'
									IdDec        = $idDec
									IdHex        = $idHex
									Tag          = ($tag+'PS')
									Type         = $type
									TypeDesc     = $typeDesc
									Length       = $length
									ValueBytes   = $valueBytes
									ValueDecoded = $psTime
									ValueDisplay = $psTime
								}
							}
						}
					}
				}
				Catch
				{
					Throw
				}
			}
			$bitmap.Dispose()
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
