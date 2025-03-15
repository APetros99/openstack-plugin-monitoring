from flask import Flask, jsonify
import openstack

app = Flask(__name__)

# Connessione a OpenStack
conn = openstack.connect()

@app.route('/status')
def get_openstack_status():
    # Recupera tutte le istanze attive
    servers = conn.compute.servers()
    instances = [{"name": s.name, "status": s.status} for s in servers]

    # Recupera i volumi
    volumes = conn.block_storage.volumes()
    volume_list = [{"name": v.name, "size": v.size, "status": v.status} for v in volumes]

    # Recupera le reti
    networks = conn.network.networks()
    network_list = [{"name": n.name, "status": n.status} for n in networks]

    return jsonify({
        "instances": instances,
        "volumes": volume_list,
        "networks": network_list
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
