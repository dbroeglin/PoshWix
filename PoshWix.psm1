$ErrorActionPreference = "Stop"

function Write-WixModulePackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $SourceDir,

        [Parameter(Mandatory = $true)]
        [String]
        $ModuleName,
		
        [String]
        $Wix = "Wix.wxs",
		
		[String]
		$WixHome = "C:\Program Files (x86)\WiX Toolset v3.10\bin"
		
    )

	Write-Host "Creating a package from directory '.'"
	
    $TempDir = Join-Path $env:TEMP $([guid]::NewGuid())
	$TempWorkDir = Join-Path $TempDir PoshWixTmp
    $TempSourceDir = Join-Path $TempDir SourceDirTmp
	mkdir -Force $TempWorkDir
    mkdir -Force $TempSourceDir
	$DirectoryWxs = Join-Path $TempWorkDir "directory.wxs"
    
    Copy-Item $SourceDir/* $TempSourceDir -Exclude wix.msi,wix.wixpdb
    
	& "$WixHome\heat.exe" dir $TempSourceDir -var var.MySource -cg NewFilesGroup -g1 -sf -srd  -v -gg -sfrag -template fragment -dr ModuleFolder -out $DirectoryWxs
	& "$WixHome\candle.exe" -arch x64 -wx -v "-dModuleName=$ModuleName" wix.wxs -o $TempWorkDir\wix.wixobj
    & "$WixHome\candle.exe" -arch x64 -wx -v "-dMySource=$SourceDir" $DirectoryWxs -o $TempWorkDir\directory.wixobj
	& "$WixHome\light.exe" -wx $TempWorkDir\wix.wixobj $TempWorkDir\directory.wixobj -o wix.msi 
}