# AzureCLI Pws
# URL Material https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-powershell

# Resource Group
New-AzResourceGroup -Name 'actividad2' -Location 'EastUS'
$Username = $env:AZURE_USERNAME
$Password = ConvertTo-SecureString -String $env:AZURE_PASSWORD -AsPlainText -Force

# Create a credential obj
$Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)

# Create VM
New-AzVm -ResourceGroupName 'actividad2' -Name 'vm-actividad-2' -Location 'EastUS' -Image 'MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest' -VirtualNetworkName 'myVnet' -SubnetName 'mySubnet' -SecurityGroupName 'myNetworkSecurityGroup' -PublicIpAddressName 'myPublicIpAddress' -OpenPorts 80, 3389 -Credential $Credential    

# Install SII
Invoke-AzVMRunCommand -ResourceGroupName 'actividad2' -VMName 'vm-actividad-2' -CommandId 'RunPowerShellScript' -ScriptString 'Install-WindowsFeature -Name Web-Server -IncludeManagementTools'    

#Request public IP for vm-actividad-2 
$ipPublica = Get-AzPublicIpAddress -ResourceGroupName actividad2 | Select-Object -ExpandProperty IpAddress

# Haz una solicitud HTTP a la dirección IP
$respuesta = Invoke-WebRequest -Uri "http://$ipPublica" -ErrorAction Stop

# Verifica si la respuesta no es nula y si contiene "<!DOCTYPE html>" (ignorando las mayúsculas)
if ($respuesta -ne $null -and $respuesta.Content -like "*<!DOCTYPE html*" -or $respuesta.Content -like "*<!doctype html*") {
    Write-Output "web ok"
    # Remove Resource group created
} else {
    # Maneja la situación en la que la respuesta no es null o no contiene "<!DOCTYPE html>"
    Write-Output "La respuesta no es una página HTML o hay un error en la respuesta."
}
# Remove Resource group created
Remove-AzResourceGroup -Name 'actividad2' -Force