#!/bin/bash

# Imposta i percorsi assoluti per garantire che le directory siano sempre corrette
PLUGIN_DIR=$(realpath /opt/stack/openstack-plugin-monitoring)
APP_DIR=$(realpath "$PLUGIN_DIR/app")
SERVICE_DIR=$(realpath "$PLUGIN_DIR/devstack/service")
SYSTEMD_DIR=$(realpath /etc/systemd/system)

# Log dei percorsi per debug
echo "Paths in use:"
echo "PLUGIN_DIR: $PLUGIN_DIR"
echo "APP_DIR: $APP_DIR"
echo "SERVICE_DIR: $SERVICE_DIR"
echo "SYSTEMD_DIR: $SYSTEMD_DIR"

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
    echo "Installing Python app dependencies..."

    # Controlla se la directory esiste
    if [[ ! -d "$APP_DIR" ]]; then
        echo "ERROR: Directory $APP_DIR does not exist."
        exit 1
    fi

    # Crea la virtual environment se non esiste
    if [[ ! -d "$APP_DIR/venv" ]]; then
        echo "Creating virtual environment in $APP_DIR/venv"
        python3 -m venv "$APP_DIR/venv" || { echo "ERROR: Failed to create virtual environment"; exit 1; }
    fi

    # Attiva la virtual environment
    echo "Activating virtual environment"
    source "$APP_DIR/venv/bin/activate"

    # Controlla la presenza di requirements.txt
    if [[ ! -f "$APP_DIR/requirements.txt" ]]; then
        echo "ERROR: requirements.txt not found in $APP_DIR"
        deactivate
        exit 1
    fi

    # Installa le dipendenze
    echo "Installing dependencies from requirements.txt"
    pip install -r "$APP_DIR/requirements.txt" || { 
        echo "ERROR: Failed to install dependencies"; 
        deactivate
        exit 1
    }

    # Disattiva la virtual environment
    deactivate
    echo "Python app dependencies installed successfully"
}

function copy_service_file {
    echo "Copying monitoring service file to systemd directory..."

    # Verifica che il file di servizio esista
    if [[ ! -f "$SERVICE_DIR/openstack-plugin-monitoring.service" ]]; then
        echo "ERROR: Service file not found at $SERVICE_DIR/openstack-plugin-monitoring.service"
        exit 1
    fi

    # Copia il file di servizio nella directory di systemd
    sudo cp "$SERVICE_DIR/openstack-plugin-monitoring.service" "$SYSTEMD_DIR" || { 
        echo "ERROR: Failed to copy service file"; 
        exit 1 
    }

    # Abilita il servizio e ricarica systemd
    sudo systemctl enable openstack-plugin-monitoring.service || { 
        echo "ERROR: Failed to enable the systemd service"; 
        exit 1 
    }

    sudo systemctl daemon-reload || { 
        echo "ERROR: Failed to reload systemd daemon"; 
        exit 1 
    }

    echo "Service file copied successfully, and systemd reloaded"
}

function start_monitoring_plugin {
    echo "Starting monitoring Flask app service..."
    sudo systemctl start openstack-plugin-monitoring.service || { 
        echo "ERROR: Failed to start the monitoring service"; 
        exit 1 
    }
    echo "Monitoring service started successfully"
}

function configure_monitoring_plugin {
    echo "Configuring monitoring plugin..."
    # Qui eventuali ulteriori configurazioni
}

# Gestione del ciclo di vita del plugin con DevStack
if is_service_enabled openstack-plugin-monitoring; then
    if [[ "$1" == "stack" && "$2" == "pre-install" ]]; then
        echo "Pre-install step for monitoring Plugin - nothing to do here."

    elif [[ "$1" == "stack" && "$2" == "install" ]]; then
        echo "Installing Monitoring Plugin"
        install_grafana
        install_app_dependencies
        copy_service_file

    elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
        echo "Configuring Monitoring Plugin"
        configure_monitoring_plugin

    elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
        echo "Initializing Monitoring Plugin"
        start_monitoring_plugin
    fi

    if [[ "$1" == "unstack" ]]; then
        echo "Stopping Monitoring service..."
        sudo systemctl stop openstack-plugin-monitoring.service || { 
            echo "ERROR: Failed to stop the monitoring service"; 
            exit 1 
        }
        uninstall_grafana
    fi

    if [[ "$1" == "clean" ]]; then
        echo "Cleaning systemd service file..."
        sudo rm "$SYSTEMD_DIR/openstack-plugin-monitoring.service" || { 
            echo "ERROR: Failed to remove the monitoring service file"; 
            exit 1 
        }
    fi
fi
