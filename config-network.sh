#!/bin/bash

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "Este script debe ejecutarse como root"
    exit 1
fi

# Verificar si se proporcionó el hostname como parámetro
if [ -z "$1" ]; then
    echo "Debe proporcionar un hostname como parámetro"
    echo "Uso: $0 nuevo-hostname"
    exit 1
fi

NEW_HOSTNAME="$1"

# Cambiar el hostname
echo "$NEW_HOSTNAME" > /etc/hostname
hostnamectl set-hostname "$NEW_HOSTNAME"

# Actualizar /etc/hosts
sed -i "s/^127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts

# Obtener la información de red actual
INTERFACE=$(ip route | grep default | awk '{print $5}')
CURRENT_IP=$(ip addr show $INTERFACE | grep "inet " | awk '{print $2}' | cut -d/ -f1)
GATEWAY=$(ip route | grep default | awk '{print $3}')
NETMASK=$(ip addr show $INTERFACE | grep "inet " | awk '{print $2}' | cut -d/ -f2)
DNS1="8.8.8.8"
DNS2="8.8.4.4"

# Crear backup del archivo de configuración de red
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.backup.$TIMESTAMP

# Crear nueva configuración de red
cat > /etc/netplan/00-installer-config.yaml << EOF
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $CURRENT_IP/$NETMASK
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS1, $DNS2]
EOF

# Aplicar cambios de red
echo "Aplicando configuración de red..."
netplan apply

echo "Configuración completada:"
echo "Nuevo hostname: $NEW_HOSTNAME"
echo "IP estática: $CURRENT_IP"
echo "Interface: $INTERFACE"
echo "Gateway: $GATEWAY"
echo "Se ha creado un backup de la configuración anterior en: /etc/netplan/00-installer-config.yaml.backup.$TIMESTAMP"
