#!/bin/bash

source /opt/stack/openstack-plugin-monitoring/devstack/settings

function install_grafana {
    echo "Installing Grafana..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https software-properties-common wget
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
    sudo apt-get update
    sudo apt-get install -y grafana
    sudo systemctl daemon-reload
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
    echo "Grafana installed successfully!"
}

function uninstall_grafana {
    echo "Removing Grafana..."
    sudo systemctl stop grafana-server
    sudo apt-get purge -y grafana
    sudo apt-get autoremove -y
    echo "Grafana removed successfully!"
}

function install_app_dependencies {
    echo "Installing Python app requirements..."
    sudo pip3 install -r $APP_DIR/requirements.txt
}

function configure_app_service {
    echo "Configuring systemd service for OpenStack monitoring app..."
    sudo cp $SERVICE_DIR/openstack-plugin-monitoring.service $SYSTEMD_DIR/
    sudo systemctl enable openstack-plugin-monitoring
    sudo systemctl start openstack-plugin-monitoring
    echo "Monitoring app service started!"
}

function uninstall_app_service {
    echo "Stopping and removing monitoring app service..."
    sudo systemctl stop openstack-plugin-monitoring
    sudo systemctl disable openstack-plugin-monitoring
    sudo rm -f $SYSTEMD_DIR/openstack-plugin-monitoring.service
    sudo systemctl daemon-reload
    echo "Monitoring app service removed successfully!"
}

if is_service_enabled openstack-plugin-monitoring; then
    case "$1" in
        stack)
            case "$2" in
                install)
                    install_grafana
                    sudo pip3 install -r $APP_DIR/requirements.txt
                    configure_app_service
                    ;;
                post-config)
                    configure_app_service
                    ;;
            esac
    fi

    if [[ "$1" == "unstack" ]]; then
        uninstall_app_service
        uninstall_grafana
    fi
fi
