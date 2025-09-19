import requests
import sys
from flask import Flask, jsonify

app = Flask(__name__)

# Store the port values globally (will be set from command line arguments)
port_to_check = None
flask_bind_port = None
main_container_name = None  # Add the main container's name

def check_port_health():
    url = f"http://{main_container_name}:{port_to_check}"

    try:
        # Make a GET request to the specified port on the main container
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
    if status_code in [200, 401, 403, 404, 500]:
        return jsonify({"status": "healthy", "code": status_code}), 200
    else:
        return jsonify({"status": "unhealthy", "code": status_code}), 500

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python healthcheck.py <port_to_check> <flask_bind_port> <main_container_name>")
        sys.exit(1)

    # Get the port to check from the command-line arguments
    port_to_check = sys.argv[1]
    flask_bind_port = sys.argv[2]
    main_container_name = sys.argv[3]

    # Validate ports
    try:
        port_to_check = int(port_to_check)
        flask_bind_port = int(flask_bind_port)
    except ValueError:
        print("Invalid port number.")
        sys.exit(1)

    # Run the Flask app on the specified bind port
    app.run(host="0.0.0.0", port=flask_bind_port)
