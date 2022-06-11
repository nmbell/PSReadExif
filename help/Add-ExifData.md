# Add-ExifData

## SYNOPSIS
Adds EXIF data from an image file to the file properties.

## SYNTAX

```
Add-ExifData [-Path] <String> [-TagId <String[]>] [-NoPSData] [-ShowUnknown] [<CommonParameters>]
```

## DESCRIPTION
Adds EXIF data from an image file to the file properties.
Tags known to the \[System.Drawing.Bitmap\] class are decoded with the corresponding tag name.
To see a list of known tags, use Get-ExifTag.
Unknown tags may also be retrieved.
Some selected tags are used to create artifical tags that have a PS object for the data returned, e.g. DateTimePS is created from the DateTime tag.
Any file can be passed to the function, but EXIF data will not be included for files that do not have recognizable EXIF data.

## EXAMPLES

### EXAMPLE 1
```
## Add all known EXIF data to the file object ##

PS C:\> $Path = 'C:\my\images\Canon.jpg'
PS C:\> Get-Item -Path $Path | Add-ExifData | Select-Object -ExpandProperty ExifData
```

### EXAMPLE 2
```
## Add all known EXIF data for a file, suppressing artificial data ##

PS C:\> $Path = 'C:\my\images\Canon.jpg'
PS C:\> Get-Item -Path $Path | Add-ExifData -NoPSData | Select-Object -ExpandProperty ExifData
```

### EXAMPLE 3
```
## Add EXIF data for specific tags for a file ##

PS C:\> $Path = 'C:\my\images\Canon.jpg'
PS C:\> Get-Item -Path $Path | Add-ExifData -TagId 271,'272',0x11A,([Int32]'0x11B'),Orientation,'*ISO*' | Select-Object -ExpandProperty ExifData
```

### EXAMPLE 4
```
## Add all known and unknown EXIF data for a file ##

PS C:\> $Path = 'C:\my\images\Canon.jpg'
PS C:\> Get-Item -Path $Path | Add-ExifData -ShowUnknown | Select-Object -ExpandProperty ExifData
```

### EXAMPLE 5
```
## Add EXIF data for a specific tag for all files in a directory, including the file name in the output ##

PS C:\> $Path = 'C:\my\images'
PS C:\> Get-ChildItem -Path $Path -PipelineVariable pv | Add-ExifData -TagId DateTimePS | Select-Object -ExpandProperty ExifData | Format-Table @{n='File';e={$pv.Name}},Key,Value
```

## PARAMETERS

### -NoPSData
Exclude artificial data (additional data for selected tags as PS objects).

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Path to the image file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ShowUnknown
Include unknown data points in the output.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TagId
List of tag ids to be included.
TagIds can be entered as either decimals, hex values, or strings.
Wildcard characters are supported for string values.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Id

Required: False
Position: Named
Default value: @('*')
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## NOTES
Author : nmbell

## RELATED LINKS

[https://docs.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-constant-property-item-descriptions](https://docs.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-constant-property-item-descriptions)



