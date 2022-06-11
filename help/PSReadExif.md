# PSReadExif 1.0.0

[SHORT DESCRIPTION](#short-description)

[LONG DESCRIPTION](#long-description)

- [The module functions](#the-module-functions)

[QUICK START GUIDE](#quick-start-guide)

1. [Install the module.](#1-install-the-module)

2. [Run your first command.](#2-run-your-first-command)

[RELEASE HISTORY](#release-history)

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

## SHORT DESCRIPTION
PSReadExif is a PowerShell module that reads EXIF metadata from image files using native Windows GDI+ classes.

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

## LONG DESCRIPTION
PSReadExif is a PowerShell module that reads EXIF metadata from image files using native Windows GDI+ classes.

Some image file metadata can be viewed in Windows Explorer's properties dialog, however, that data is not available natively as PowerShell file object properties.
The [`[System.Drawing.Bitmap]`](https://docs.microsoft.com/en-us/windows/win32/api/gdiplusheaders/nl-gdiplusheaders-bitmap) class (part of the [GDI+ Win32 API](https://docs.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-gdi-start)) allows access to a range of 217 [EXIF metadata properties](https://docs.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-constant-property-item-descriptions) as binary data arrays. The functions of this module use the class to access the EXIF metadata and then decode it into meaningful (human readable) form. PSReadExif cannot be used to modify or create EXIF metadata.

Note: While the 217 available metadata properties cover a lot of commonly used data points, many more exist ([ExifTool](https://exiftool.org/TagNames/) documentation notes that it recognizes more than 25,000). If you need to read image metadata that is not exposed with PSReadExif, or write any image metadata, it's recommended to use [ExifTool](https://exiftool.org/) or [another metadata editor](https://en.wikipedia.org/wiki/Comparison_of_digital_image_metadata_editors).

### The module functions

- [Get-ExifData](Get-ExifData.md)
- [Add-ExifData](Add-ExifData.md)
- [Get-ExifTag](Get-ExifTag.md)


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

## QUICK START GUIDE
### 1. Install the module.
   The [module](https://www.powershellgallery.com/packages/PSReadExif/1.0.0) is available through the [PowerShell Gallery](https://docs.microsoft.com/en-us/powershell/scripting/gallery/getting-started).
   Run the following command in a PowerShell console to install the module:
   ```
   Install-Module -Name PSReadExif -Force
   ```
   Run the following to import the module into the current session:
   ```
   Import-Module -Name PSReadExif
   ```
   To see the list of available commands:
   ```
   Get-Command -Module PSReadExif
   ```
   If you see a list of functions similar to those above, your install was successful.

### 2. Run your first command.
   To read EXIF metadata from a file:
   ```
   $Path = 'C:\my\images\Canon.jpg'
   Get-ExifData -Path $Path
   ```
   For more examples, see the [Get-ExifData](Get-ExifData.md) function help.

   To add EXIF metadata as properties of a file object:
   ```
   $Path = 'C:\my\images\Canon.jpg'
   Get-Item -Path $Path | Add-ExifData | Select-Object -ExpandProperty ExifData
   ```
   For more examples, see the [Add-ExifData](Add-ExifData.md) function help.

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

## RELEASE HISTORY
### 1.0.0 (2022-06-10)
  - Initial release
