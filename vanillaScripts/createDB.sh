#!/bin/bash
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

create_resource_group() {
    echo "Creando grupo de recursos..."
    if az group create --name $resource_group --location $location; then
        resource_group_status=true
    else
        handle_error "No se pudo crear el grupo de recursos."
    fi
}

create_sql_server() {
    echo "Creando servidor SQL..."
    echo "Resource group: $resourceGroup"
    if az sql server create --name $vm_name --resource-group $resource_group --location $location --admin-user $username --admin-password $password; then
        db_server=true
    else
        handle_error "No se pudo crear el servidor SQL."
    fi
}

# Función para realizar la limpieza de recursos
create_firewall_rules() {
    echo "Configurando firewall..."
    echo "Resource group: $resourceGroup"
    if az sql server firewall-rule create --resource-group $resourceGroup --server $server --name AllowYourIp --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0; then
        firewall_conf=true
    else
        handle_error "No se pudo eliminar el grupo de recursos."
    fi
}

create_db() {
    echo "Creando $vm_name SQL"
    echo "Resource group: $resourceGroup"
    if az sql db create --resource-group $resourceGroup --server $server --name $db_name --sample-name AdventureWorksLT --edition GeneralPurpose --compute-model Serverless --family Gen5 --capacity 2; then
        sql_status=true
    else
        handle_error "No se pudo crear el servidor SQL."
    fi
}
# Función para manejar errores
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

create_resource_group
create_sql_server
create_firewall_rules
create_db