#!/bin/bash

# Declaración de variables
resource_group_status=false
vm_status=false
webserver_status=false
sii_install_status=false
port_opened=false
db_server=false
sql_status=false
firewall_conf=false
ip_name="public"
virtualnet_status=false
public_ip_status=false
nsg_rules_status=false
ip_status=false
resource_group="actividad-2"
location="eastus"
vm_name="vm-actividad-2"
username="keaguirre"
password="Avaras.duoc2024"
nsg_name="nsg_grupo3"
nic_name="nic_grupo3"
subnet_name="grupo3"
vnet_name="vnet_grupo3"
db_name="keaguirre"

# Función para manejar errores
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Función para crear el grupo de recursos
create_resource_group() {
    echo "Creando grupo de recursos..."
    if az group create --name "$resource_group" --location "$location" --tags aay5121=grupo3; then
        resource_group_status=true
    else
        handle_error "No se pudo crear el grupo de recursos."
    fi
}

create_virtualnet_subnet(){
    echo "Creando Redvirtual y Subnet..."
    if az network vnet create --resource-group "$resource_group" --name "$vnet_name" --address-prefix "192.168.0.0/16" --subnet-name "$subnet_name" --subnet-prefix "192.168.10.0/24"; then
        virtualnet_status=true
    else
        handle_error "No se pudo crear la red virtual o la subred"
    fi
}

# IP Publica
ip_create(){
    echo "Creando IP Publica..."
    if az network public-ip create --resource-group "$resource_group" --name "$ip_name" --sku Standard --allocation-method Static; then
        public_ip_status=true
    else
        handle_error "No se pudo crear la IP Publica"
    fi
}

create_nsg(){
    echo "Creando Network Security Group..."
    if az network nsg create --resource-group "$resource_group" --name "$nsg_name"; then
        nsg_status=true
    else
        handle_error "No se pudo crear el Network Security Group"
    fi
}

nsg_rules(){
    echo "Creando reglas RDP y HTTP con origen abierto...699"
    if az network nsg rule create --resource-group "$resource_group" --nsg-name "$nsg_name" --name RDPAccess --priority 1000 --protocol Tcp --destination-port-range 3389 --access Allow --direction Inbound --source-address-prefix "0.0.0.0/0"; then
        echo "NSG RDP Rule created"
        if az network nsg rule create --resource-group "$resource_group" --nsg-name "$nsg_name" --name HTTPAccess --priority 1010 --protocol Tcp --destination-port-range 80 --access Allow --direction Inbound --source-address-prefix "0.0.0.0/0"; then
            echo "NSG HHTP Rule created"
            nsg_rules_status=true
        else
            handle_error "No se pudo crear la regla HHTP para el NSG"
        fi
    else
        handle_error "No se pudo crear la reglas RDP para el NSG"
    fi

}

check_ip(){
    while :; do
        ip_address=$(az network public-ip show --name "$ip_name" --resource-group "$resource_group" --query ipAddress --output tsv 2>/dev/null)
        if [[ -n "$ip_address" && "$ip_address" != "null" ]]; then
            sleep 2
            echo "La IP pública encontrada es: $ip_address"
            ip_status=true
            break # Salir del bucle cuando la IP pública esté disponible
        else
            echo "Aún no... comprobando nuevamente"
            sleep 10 # Esperar 10 segundos antes de intentarlo de nuevo
        fi
    done
}

create_nic(){
    if az network nic create --resource-group "$resource_group" --name "$nic_name" --vnet-name "$vnet_name" --subnet "$subnet_name" --network-security-group "$nsg_name" --public-ip-address "$ip_name"; then
        nic_status=true
    else
        handle_error "Error al crear NIC (Network Interface Card)..."
    fi
}

# Función para crear la máquina virtual
create_vm() {
    echo "Creando máquina virtual..."
    if az vm create --resource-group "$resource_group" --name "$vm_name" --image MicrosoftWindowsServer:WindowsServer:2019-datacenter:latest --public-ip-sku Standard --admin-username "$username" --admin-password "$password" --tags aay5121=grupo3; then
        vm_status=true
    else
        handle_error "No se pudo crear la máquina virtual."
    fi
}

# Función para instalar el servidor web en la máquina virtual
install_web_server() {
    echo "Instalando servidor web en la máquina virtual..."
    if az vm run-command invoke -g "$resource_group" -n "$vm_name" --command-id RunPowerShellScript --scripts "Install-WindowsFeature -name Web-Server -IncludeManagementTools"; then
        sii_install_status=true
    else
        handle_error "No se pudo instalar el servidor web."
    fi
}

# Function to check web server status
check_web_server_status() {
    # Show public ip
    ip_publica=$(az vm show --resource-group $resource_group --name $vm_name --show-details | jq -r '.publicIps')

    # Check with curl public ip, if retrieves an html response then everything is ok
    response=$(curl -sSL "http://$ip_publica")
    echo response: "$response"

    if [ -n "$response" ]; then
        if [[ $(awk '/<!DOCTYPE html|<!doctype html/ {print}' <<< "$response") ]]; then
            echo "Web server is running."
            webserver_status=true
            # Delete created resource group
            az group delete --name $resource_group
        else
            echo "The response is not an HTML page or there is an error in the response."
            az group delete --name $resource_group
        fi
    else
        echo "The response is null."
        az group delete --name $resource_group
    fi
}

# Función para abrir el puerto 80 en la máquina virtual
open_port_80() {
    echo "Abriendo puerto 80 en la máquina virtual..."
    if az vm open-port --port 80 --resource-group "$resource_group" --name "$vm_name"; then
        port_opened=true
    else
        handle_error "No se pudo abrir el puerto 80."
    fi
}

# Create DB

create_sql_server() {
    echo "Creando servidor SQL..."
    if az sql server create --name "$vm_name" --resource-group "$resource_group" --location "$location" --admin-user "$username" --admin-password "$password"; then
        db_server=true
    else
        handle_error "No se pudo crear el servidor SQL."
    fi
}

# Función para realizar la limpieza de recursos
create_firewall_rules() {
    echo "Configurando firewall..."
    if az sql server firewall-rule create --resource-group "$resource_group" --server "$vm_name" --name AllowYourIp --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0; then
        firewall_conf=true
    else
        handle_error "No se pudo eliminar el grupo de recursos."
    fi
}

create_db() {
    echo "Creando $vm_name SQL"
    if az sql db create --resource-group "$resource_group" --server "$vm_name" --name "$db_name" --sample-name AdventureWorksLT --edition GeneralPurpose --compute-model Serverless --family Gen5 --capacity 2; then
        sql_status=true

        # Comando sqlcmd para ejecutar una consulta de prueba
        echo "Ejecutando consulta de prueba en la base de datos..."
        if sqlcmd -S "$vm_name.database.windows.net" -d "$db_name" -U "$username" -P "$password" -Q "SELECT TOP 20 pc.Name as CategoryName, p.name as ProductName FROM SalesLT.ProductCategory pc JOIN SalesLT.Product p ON pc.productcategoryid = p.productcategoryid;"; then
            echo "Consulta ejecutada exitosamente."
        else
            handle_error "No se pudo ejecutar la consulta de prueba."
        fi

    else
        handle_error "No se pudo crear el servidor SQL."
    fi
}


# Función para realizar la limpieza de recursos
cleanup_resources() {
    echo "Limpiando recursos..."
    if az group delete --name "$resource_group" --yes; then
        cleanup_done=true
    else
        handle_error "No se pudo eliminar el grupo de recursos."
    fi
}

# Manejar errores y ejecutar funciones en orden
create_resource_group
if $resource_group_status; then
    create_virtualnet_subnet
fi    
if $virtualnet_status; then
    ip_create
fi    
if $public_ip_status; then
    create_nsg
fi    
if $nsg_status; then
    nsg_rules
fi
if $nsg_rules_status; then
    check_ip
fi
if $ip_status; then
    create_nic
fi
if $nic_status; then
    create_vm
fi
if $vm_status; then
    install_web_server
fi
if $sii_install_status; then
    check_web_server_status
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