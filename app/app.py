from flask import Flask
import requests

app = Flask(__name__)

@app.route("/")
def home():
    try:
        response = requests.get('http://localhost:3000/api/health')
        if response.status_code == 200:
            return "Grafana API is reachable!"
        else:
            return f"Grafana API unreachable, status: {response.status_code}", 500
    except Exception as e:
        return f"Error connecting to Grafana API: {e}", 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5001)
