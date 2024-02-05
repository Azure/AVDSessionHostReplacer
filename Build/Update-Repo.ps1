[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[string]
	$TokenAccount,

	[Parameter(Mandatory = $true)]
	[string]
	$GitToken,

	[Parameter(Mandatory = $true)]
	[string]
	$AccountName,

	[Parameter(Mandatory = $true)]
	[string]
	$RepositoryName,

	[string]
	$Message = 'CI_UPDATE'
)

$repositoryRoot = Split-Path $PSScriptRoot
Push-Location -Path $repositoryRoot
try {
	git config --global user.name 'Git bot'
	git config --global user.email 'bot@noreply.github.com'
	git add .
	git commit -a -m $Message
	git push "https://$($TokenAccount):$GitToken@github.com/$AccountName/$RepositoryName.git"
}
finally {
	Pop-Location
}