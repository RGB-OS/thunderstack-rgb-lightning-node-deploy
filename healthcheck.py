import requests
import sys
from flask import Flask, jsonify

app = Flask(__name__)

# Store the port values globally (will be set from command line arguments)
port_to_check = None
flask_bind_port = None

def check_port_health():
    url = f"http://localhost:{port_to_check}"

    try:
        # Make a GET request to the specified port
        response = requests.get(url)

        # Check the status code and return accordingly
        if response.status_code == 200:
            return 200
        elif response.status_code == 403:
            return 403
        elif response.status_code == 404:
            return 404
        else:
            return response.status_code

    except requests.ConnectionError:
        return 500

@app.route('/health', methods=['GET'])
def health_check():
    status_code = check_port_health()
    if status_code == 200:
        return jsonify({"status": "healthy", "code": 200}), 200
    elif status_code == 403:
        return jsonify({"status": "forbidden", "code": 200}), 200
    elif status_code == 404:
        return jsonify({"status": "not found", "code": 200}), 200
    else:
        return jsonify({"status": "unhealthy", "code": status_code}), 500

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python healthcheck.py <port_to_check> <flask_bind_port>")
        sys.exit(1)

    # Get the port to check from the command-line argument
    port_to_check = sys.argv[1]
    try:
        port_to_check = int(port_to_check)
    except ValueError:
        print("Invalid port number to check.")
        sys.exit(1)

    # Get the Flask bind port from the command-line argument
    flask_bind_port = sys.argv[2]
    try:
        flask_bind_port = int(flask_bind_port)
    except ValueError:
        print("Invalid Flask bind port.")
        sys.exit(1)

    # Run the Flask app on the specified bind port
    app.run(host="0.0.0.0", port=flask_bind_port)
