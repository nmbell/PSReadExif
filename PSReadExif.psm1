# PSReadExif 1.0.2
If (!$IsWindows)
{
	Write-Host 'PSReadExif is only available for Windows.'
	Exit
}

# Include files
. "$PSScriptRoot\functions\Add-ExifData.ps1"
. "$PSScriptRoot\functions\Get-ExifData.ps1"
. "$PSScriptRoot\functions\Get-ExifTag.ps1"
. "$PSScriptRoot\functions\Get-ExifType.ps1"


# Initialize variables
$script:PSModuleRoot        = $PSScriptRoot
$script:tagDescriptionsPath = "$script:PSModuleRoot\data\TagsList.csv"
$script:dataTypesPath       = "$script:PSModuleRoot\data\DataTypes.csv"
$script:tags                = Get-ExifTag -AsHashTable
$script:types               = Get-ExifType


# Functions to export
$FunctionsToExport = @(
	'Add-ExifData'
	'Get-ExifData'
	'Get-ExifTag'
	# 'Get-ExifType'
)


# Cmdlets to export
$CmdletsToExport = @()


# Variables to export
$VariablesToExport = @()


# Aliases to export
$AliasesToExport = @()


# Export the members
$moduleMembers = @{
	Function = $FunctionsToExport
	Cmdlet   = $CmdletsToExport
	Variable = $VariablesToExport
	Alias    = $AliasesToExport
}
Export-ModuleMember @moduleMembers


# Update type data
$typeData = @{
    TypeName                  = 'PSReadExif'
    DefaultDisplayPropertySet = 'IdDec','IdHex','Tag','ValueDisplay'
}
Update-TypeData @typeData -Force
