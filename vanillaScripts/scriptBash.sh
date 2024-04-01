#!/bin/bash

# Declaración de variables
resource_group="actividad-2"
location="eastus"
vm_name="vm-actividad-2"
username="keaguirre"
password="Avaras.duoc2024"
resource_group_status=false
vm_status=false
webserver_status=false
port_opened=false
db_server=false
sql_status=false
firewall_conf=false
db_name="keaguirre"

# Función para manejar errores
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Función para crear el grupo de recursos
create_resource_group() {
    echo "Creando grupo de recursos..."
    if az group create --name $resource_group --location $location; then
        resource_group_status=true
    else
        handle_error "No se pudo crear el grupo de recursos."
    fi
}

# Función para crear la máquina virtual
create_vm() {
    echo "Creando máquina virtual..."
    if az vm create --resource-group $resource_group --name $vm_name --image MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest --public-ip-sku Standard --admin-username $username --admin-password $password; then
        vm_status=true
    else
        handle_error "No se pudo crear la máquina virtual."
    fi
}

# Función para instalar el servidor web en la máquina virtual
install_web_server() {
    echo "Instalando servidor web en la máquina virtual..."
    if az vm run-command invoke -g $resource_group -n $vm_name --command-id RunPowerShellScript --scripts "Install-WindowsFeature -name Web-Server -IncludeManagementTools"; then
        webserver_status=true
    else
        handle_error "No se pudo instalar el servidor web."
    fi
}

# Función para abrir el puerto 80 en la máquina virtual
open_port_80() {
    echo "Abriendo puerto 80 en la máquina virtual..."
    if az vm open-port --port 80 --resource-group $resource_group --name $vm_name; then
        port_opened=true
    else
        handle_error "No se pudo abrir el puerto 80."
    fi
}

# Create DB

create_sql_server() {
    echo "Creando servidor SQL..."
    if az sql server create --name $vm_name --resource-group $resource_group --location $location --admin-user $username --admin-password $password; then
        db_server=true
    else
        handle_error "No se pudo crear el servidor SQL."
    fi
}

# Función para realizar la limpieza de recursos
create_firewall_rules() {
    echo "Configurando firewall..."
    if az sql server firewall-rule create --resource-group $resourceGroup --server $server --name AllowYourIp --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0; then
        firewall_conf=true
    else
        handle_error "No se pudo eliminar el grupo de recursos."
    fi
}

create_db() {
    echo "Creando $vm_name SQL"
    if az sql db create --resource-group $resourceGroup --server $server --name $db_name --sample-name AdventureWorksLT --edition GeneralPurpose --compute-model Serverless --family Gen5 --capacity 2; then
        sql_status=true
    else
        handle_error "No se pudo crear el servidor SQL."
    fi
}

# Función para realizar la limpieza de recursos
cleanup_resources() {
    echo "Limpiando recursos..."
    if az group delete --name $resource_group --yes; then
        cleanup_done=true
    else
        handle_error "No se pudo eliminar el grupo de recursos."
    fi
}

# Manejar errores y ejecutar funciones en orden
create_resource_group
if $resource_group_status; then
    create_vm
fi
if $vm_status; then
    install_web_server
fi
if $webserver_status; then
    open_port_80
fi
if $port_opened; then
    create_sql_server
fi
if $db_server; then
    create_firewall_rules
fi
if $firewall_conf; then
    create_db
fi
if $sql_status; then
    cleanup_resources
fi
if $cleanup_done; then
    echo "Script terminado"
fi