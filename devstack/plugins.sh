#!/bin/bash

# Carica settings
source /opt/stack/openstack-plugin-monitoring/devstack/settings

function install_grafana {
    echo "Installing Grafana..."
    sudo apt update
    sudo apt install -y apt-transport-https software-properties-common wget
    wget -q -O - https://apt.grafana.com/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/grafana.gpg
    echo "deb https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
    sudo apt update
    sudo apt install -y grafana
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
    echo "Grafana installed successfully!"
}

function configure_grafana {
    echo "Configuring Grafana..."
    # (opzionale) inserire qui eventuali configurazioni aggiuntive, ad esempio datasource OpenStack
}

function uninstall_grafana {
    echo "Removing Grafana..."
    sudo systemctl stop grafana-server
    sudo apt purge -y grafana
    sudo apt autoremove -y
    echo "Grafana removed successfully!"
}

if is_service_enabled openstack-plugin-monitoring; then
    if [[ "$1" == "stack" && "$2" == "install" ]]; then
        install_grafana
    fi

    if [[ "$1" == "stack" && "$2" == "post-config" ]]; then
        echo "No additional post-config steps required."
    fi

    if [[ "$1" == "unstack" ]]; then
        uninstall_grafana
    fi

    if [[ "$1" == "clean" ]]; then
        uninstall_grafana
    fi
fi
