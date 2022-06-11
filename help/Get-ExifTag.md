# Get-ExifTag

## SYNOPSIS
Returns a list of tags known to the \[System.Drawing.Bitmap\] class.

## SYNTAX

```
Get-ExifTag [-AsHashTable] [<CommonParameters>]
```

## DESCRIPTION
Returns a list of tags known to the \[System.Drawing.Bitmap\] class.

## EXAMPLES

### EXAMPLE 1
```
## Get all known EXIF tags ##

PS C:\> Get-ExifTag
```

### EXAMPLE 2
```
## Get all known EXIF tags as a hash table ##

PS C:\> Get-ExifTag -AsHashTable
```

## PARAMETERS

### -AsHashTable
Returns data as a hash table.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## NOTES
Author : nmbell

## RELATED LINKS

[https://docs.microsoft.com/en-us/dotnet/api/system.drawing.imaging.propertyitem.id?view=dotnet-plat-ext-6.0](https://docs.microsoft.com/en-us/dotnet/api/system.drawing.imaging.propertyitem.id?view=dotnet-plat-ext-6.0)



