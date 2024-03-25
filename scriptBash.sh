#!/bin/bash
# AzureCLI Bash
# URL Material https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-cli

# Set variables 4 resource group
resource_group="actividad-2"
location="eastus"

# Vars for Create VM
vm_name="vm-actividad-2"
username="$AZURE_VM_USERNAME"
password="$AZURE_VM_PASSWORD"

# Resource Group
az group create --name $resource_group --location $location

# Create VM retrieves a json obj and Take a note your own publicIpAddress in the output when you create your VM. 
az vm create --resource-group $resource_group --name $vm_name --image MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest --public-ip-sku Standard --admin-username $username --admin-password $password

# Install SII
az vm run-command invoke -g $resource_group -n $vm_name --command-id RunPowerShellScript --scripts "Install-WindowsFeature -name Web-Server -IncludeManagementTools"

# Open webserver port
az vm open-port --port 80 --resource-group $resource_group --name $vm_name

# Show public ip
ip_publica=$(az vm show --resource-group $resource_group --name $vm_name --show-details | jq -r '.publicIps')

# Check with curl public ip, if retrieves an html response then everything is ok
response=$(curl -sSL "http://$ip_publica")
echo response: $response

if [ -n "$response" ]; then
  if [[ $(awk '/<!DOCTYPE html|<!doctype html/ {print}' <<< "$response") ]]; then
    echo "web ok"
    # Eliminar grupo de recursos creado
    az group delete --name $resource_group
  else
    echo "La respuesta no es una página HTML o hay un error en la respuesta."
    az group delete --name $resource_group
  fi
else
  echo "La respuesta es nula."
  az group delete --name $resource_group
fi

# CleanUP Resources
# az group delete --name actividad-2
echo "Script ok, eliminando los recursos usados"
az group delete --name $resource_group