from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    print("La route / è stata chiamata!")
    return 'Hello, World!'

if __name__ == '__main__':
    print("Avvio dell'app Flask...")
    app.run(host='0.0.0.0', port=5234)