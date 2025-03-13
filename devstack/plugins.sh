#!/bin/bash

# Carica il file settings
source /opt/stack/openstack-plugin-monitoring/devstack/settings

# Installazione di Grafana
function install_grafana {
    echo "Installing Grafana..."
    sudo apt update
    sudo apt install -y grafana
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
    echo "Grafana installed successfully!"
}

# Funzione per disinstallare e pulire
function uninstall_grafana {
    echo "Removing Grafana..."
    sudo systemctl stop grafana-server
    sudo apt purge -y grafana
    sudo apt autoremove -y
    echo "Grafana removed successfully!"
}

if is_service_enabled openstack-plugin-monitoring; then
    case "$1" in
        stack)
            case "$2" in
                install)
                    install_grafana
                    ;;
                post-config)
                    # eventuale configurazione aggiuntiva qui
                    ;;
            esac
            ;;
        unstack)
            uninstall_grafana
            ;;
    esac
fi
