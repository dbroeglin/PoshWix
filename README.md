# PoshWix
PoshWix is an opinionated and trivially simple tool to produce MSI packages from PowerShell modules

# Getting started

Ensure the WIX toolset is installed (see http://wixtoolset.org/)

Install the PoshWix module and, in a PowerShell module source directory create 
a WIX specification with the same name as your module (for instance `FooBar.wxs`). You can use
the current module's `PoshWix.wxs` file as a sample (juste ensure you change the 
UpgradeCode to something else). Then execute:

    Write-WixModulePackage

You should get a nice MSI that will install 

# Documentation

    help Write-WixModulePackage
  
# Disclaimer

This is a work in progress. It is provided without warranty, 
even the implied warranty of merchantability, satisfaction or 
fitness for a particular use.
