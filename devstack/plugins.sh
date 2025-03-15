#!/bin/bash

source /opt/stack/openstack-plugin-monitoring/devstack/settings

function install_grafana {
    echo "Installing Grafana..."
    sudo apt update
    sudo apt install -y grafana
}

function configure_grafana_service {
    echo "Configuring Grafana service..."
    sudo cp $SERVICE_DIR/openstack-plugin-monitoring.service $SYSTEMD_DIR
    sudo systemctl daemon-reload
    sudo systemctl enable openstack-plugin-monitoring
    sudo systemctl start openstack-plugin-monitoring
}

function uninstall_grafana_service {
    echo "Removing Grafana service..."
    sudo systemctl stop openstack-plugin-monitoring
    sudo systemctl disable openstack-plugin-monitoring
    sudo rm -f $SYSTEMD_DIR/openstack-plugin-monitoring.service
    sudo apt purge -y grafana
    sudo apt autoremove -y
    sudo systemctl daemon-reload
}

if is_service_enabled openstack-plugin-monitoring; then
    if [[ "$1" == "stack" && "$2" == "install" ]]; then
        install_grafana
        configure_grafana_service
    fi

    if [[ "$1" == "unstack" ]]; then
        uninstall_grafana_service
    fi
fi
