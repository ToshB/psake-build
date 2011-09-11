Import-Module .\Build\psake-contrib\teamcity.psm1

properties { 
	$BaseDir = Resolve-Path ".\"
	$SolutionFile = Resolve-Path $BaseDir\*.sln
	$OutputDir = "$BaseDir\Out\"
	$NuGetOutputDir = "$OutputDir\NuGet\"
	$TestAssemblies= @("*.Tests.Unit.dll","*.Tests.Integration.dll","*.Tests.dll")
	$NUnitPath = "$BaseDir\packages\NUnit.*\tools\nunit-console.exe"
	$NuGetPath = "$BaseDir\packages\NuGet.Commandline.*\tools\NuGet.exe"
} 

$framework = '4.0'

task default -depends Build

task Init {
	Write-Host $BaseDir
}

task Clean -depends Init {
    Remove-Item $OutputDir -recurse -force -ErrorAction SilentlyContinue -WhatIf:$Whatif
	Remove-Item $NuGetOutputDir -recurse -force -ErrorAction SilentlyContinue -WhatIf:$Whatif
	exec { msbuild /target:Clean /verbosity:minimal "$SolutionFile" }
} 

task Build -depends Clean{ 
	exec { msbuild /nologo /verbosity:minimal "$SolutionFile" "/p:OutDir=$OutputDir" }
} 

task Test -depends Build {
	$Tests = (Get-ChildItem "$OutputDir" -Recurse -Include $TestAssemblies)
	$NUnit = Resolve-Path $NUnitPath
	if(!$NUnit){
		throw "Could not find package NUnit at $NUnitPath, install with Install-Package NUnit"
	}
	if($Tests){
		TeamCity-TestSuiteStarted "Started a test suite"
		$old = pwd
		cd $OutputDir
	  	exec { & $NUnit /nologo $Tests }
		cd $old
		TeamCity-TestSuiteFinished "Finished a test suite" 
	}else{
		Write-Host "Nothing to test ($TestAssemblies)"
	}
}

task PackNuget {
	Remove-Item $NuGetOutputDir -recurse -force -ErrorAction SilentlyContinue
	New-Item $NuGetOutputDir -ItemType directory | out-null
	$NuGet = Resolve-Path $NuGetPath
	if(!$NuGet){
		throw "Could not find package NuGet.CommandLine at $NuGetPath, install with Install-Package NuGet.CommandLine"
	}
	$specs = (Get-ChildItem "$BaseDir" -Recurse -Include "*.nuspec")
	foreach ($spec in $specs){
		$project = $spec.FullName.Replace("nuspec", "csproj")
		exec { & $NuGet pack $project -Build -Symbols -OutputDirectory $NuGetOutputDir -Properties Configuration=Release}
	}
}