Import-Module WebAdministration

function CreateWebSite([Switch]$Whatif)
{
	New-Item IIS:\Sites\DemoSite -bindings @{protocol='http';bindingInformation=':8080:DemoSite'} -PhysicalPath C:\inetpub\DemoSite -WhatIf:$Whatif
	Set-ItemProperty 'IIS:\sites\Default Web Site\DemoApplication' -Name applicationPool -Value DemoPool -WhatIf:$Whatif
}
