$AzureEnvironment = Get-AzContext | Select-Object -ExpandProperty Environment | Select-Object -ExpandProperty Name

switch ($AzureEnvironment) {
    AzureCloud {$Location = 'eastus'; $LocationAbbreviation = 'use'}
    AzureUSGovernment {$Location = 'usgovvirginia'; $LocationAbbreviation = 'va'}
}

# Session Host Replacer
New-AzTemplateSpec `
    -ResourceGroupName $('mlz-rg-templateSpecs-dev-' + $LocationAbbreviation) `
    -Name $('ts-shr-dev-' + $LocationAbbreviation) `
    -Version 1.0 `
    -Location $Location `
    -TemplateFile 'C:\Users\jamasten\Code\AVDSessionHostReplacer\deploy\arm\DeployAVDSessionHostReplacer.json' `
    -UIFormDefinitionFile 'C:\Users\jamasten\Code\AVDSessionHostReplacer\deploy\portal-ui\portal-ui.json' `
    -Force