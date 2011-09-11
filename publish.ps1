Import-Module (Resolve-Path ..\packages\psake*\tools\psake.psm1)
Import-Module .\Pscx
Invoke-psake -taskList Archive
Remove-Module Pscx
Remove-Module psake*