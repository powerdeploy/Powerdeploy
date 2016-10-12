$folder = Get-DeploymentFolder

"init script executed" >> $folder\install.log
"init: Get-DeploymentFolder: $folder" >> $folder\install.log
"init: Get-DeploymentVariable url: $(Get-DeploymentVariable -Name url)" >> $folder\install.log
"init: Get-DeploymentVariable connection: $(Get-DeploymentVariable -Name connection)" >> $folder\install.log
"init: Get-DeploymentVariable UTF8Setting: $(Get-DeploymentVariable -Name UTF8Setting)" >> $folder\install.log