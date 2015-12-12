$ErrorActionPreference = "Stop"

function Get-ModuleInfo([String]$ModuleName) {
    $ModuleManifest = Join-Path $SourceDir "$ModuleName.psd1"
    try {
      $ModuleInfo = Test-ModuleManifest -Path $ModuleManifest
    } catch {
        $Ex = $_
        switch -wildcard ($_.FullyQualifiedErrorId) {
            "Modules_InvalidManifest,*" { Throw "Illegal format for '$ModuleManifest'" }
            "Modules_ModuleNotFound,*"  { Throw "Unable to find manifest file '$ModuleManifest'"}
            default { throw "Error while reading '$ModuleManifest': $($Ex.Exception.Message)" }
        }
    }
    $ModuleInfo
}

function Copy-SourceFiles($SourceDir, $TempDir) {
    $TempSourceDir = Join-Path $TempDir TempSourceDir
    mkdir -Force $TempSourceDir > $Null 
	
    Copy-Item $SourceDir/* $TempSourceDir -Exclude *.msi,*.wixpdb

    $TempSourceDir
}

function Write-WixModulePackage {
    <#
    .SYNOPSIS
    The Write-WixModulePackage creates a MSI package from a PowerShell module source
    directory. 
    
    .DESCRIPTION 
    The Write-WixModulePackage creates a MSI package from a PowerShell module source
    directory. 
    
    It works mostly by convention assuming that the current directory is
    typical PowerShell module directory whose name is the module name and 
    containing a .psd1 module manifest from which module metadata can be
    gathered. Both a [ModuleName].psm1 and a [ModuleName].psd1 are required in
    the SourceDir.
    
    .PARAMETER SourceDir    
    The directory where the module sources are located. Defaults to the current directory.
    
    .PARAMETER ModuleName
    The name of the module to package. This name will be reused when constructing default
    values for other parameters like Wix, or Msi.
    
    .PARAMETER ModuleVersion
    The version of the package to create. Defaults to the version found in the module 
    manifest.
    
    .PARAMETER Wix
    The name of the Wix XML specification from which the package should be created.
    Defaults to [SourceDir]\[ModuleName].wxs.
    
    .PARAMETER Msi
    The location where the MSI package should be created. Defaults to [ModuleName]-[ModuleVersion].msi
    
    .PARAMETER WixHome
    The directory where WIX is installed. Defaults to $env:WIX\bin. The WIX environment variable
    is set by the WIX installer.
    
    .EXAMPLE
    To simply package a PowerShell module execute, in the source directory:
    
    Write-WixModulePackage
    
    .EXAMPLE 
    
    To simply package a PowerShell module in directory FooBar:
    
    Write-WixModulePackage -SourceDir FooBar
    
    The MSI will be generated in the current directory.    
    #>
    [CmdletBinding()]
    param (
        [String]
        $SourceDir = ".",

        [String]    
        $ModuleName = $(Split-Path -Leaf $PSScriptRoot),
		
        [String]
        $ModuleVersion,
        
        [String]
        $Wix = $(Join-Path $SourceDir "$ModuleName.wxs"),
        
        [String]
        $Msi,
		
		[String]
		$WixHome = $(Join-Path $env:WIX bin)		
    )
    
    $ModuleInfo = Get-ModuleInfo $ModuleName
    if (!$ModuleVersion) {
       $ModuleVersion = $ModuleInfo.Version.ToString() 
    }
    if (!$Msi) {
        $Msi = "$ModuleName-$ModuleVersion.msi"
    }
	Write-Verbose "Creating '$Msi' from directory '$SourceDir' and specification '$Wix'..."
        
    $TempDir = Join-Path $env:TEMP $([guid]::NewGuid())
    $TempSourceDir = Copy-SourceFiles $SourceDir $TempDir

	$TempWorkDir = Join-Path $TempDir TempPoshWix
    $DirectoryWxs = Join-Path $TempWorkDir "Directory.wxs"
    $WixObj       = Join-Path $TempWorkDir $((Split-Path -Leaf $Wix) -replace ".wxs",".wixobj")
    $DirectoryObj = $DirectoryWxs -replace ".wxs",".wixobj"
	mkdir -Force $TempWorkDir > $Null
	    
	& "$WixHome\heat.exe" dir $TempSourceDir -var var.MySource -cg NewFilesGroup -g1 -sf -srd  -v -gg -sfrag -template fragment -dr ModuleFolder -out $DirectoryWxs
	& "$WixHome\candle.exe" -arch x64 -wx -v $Wix -o $WixObj `
        "-dModuleName=$ModuleName" `
        "-dModuleVersion=$ModuleVersion" `
        "-dManufacturer=$($ModuleInfo.CompanyName)"
    & "$WixHome\candle.exe" -arch x64 -wx -v "-dMySource=$SourceDir" $DirectoryWxs -o $DirectoryObj
	& "$WixHome\light.exe" -wx $WixObj $DirectoryObj -o $Msi -pdbout $($Msi -Replace ".msi",".pdbout")
    
	Write-Verbose "Cleaning up temporary directory '$TempDir'..."
    rm -r $TempDir 
	Write-Verbose "Done!"
}

Export-ModuleMember -Function Write-WixModulePackage