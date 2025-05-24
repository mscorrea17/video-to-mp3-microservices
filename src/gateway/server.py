import os
import gridfs
import pika
import json
import time
from flask import Flask, request, send_file, jsonify
from flask_pymongo import PyMongo
from auth import validate
from auth_svc import access
from storage import util
from bson.objectid import ObjectId
from werkzeug.utils import secure_filename

server = Flask(__name__)

# Configuration
server.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100MB max file size
ALLOWED_EXTENSIONS = {'mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'}

# MongoDB connections with error handling
try:
    mongo_video = PyMongo(server, uri="mongodb://host.minikube.internal:27017/videos")
    mongo_mp3 = PyMongo(server, uri="mongodb://host.minikube.internal:27017/mp3s")
    
    fs_videos = gridfs.GridFS(mongo_video.db)
    fs_mp3s = gridfs.GridFS(mongo_mp3.db)
    print("✓ MongoDB connections established")
except Exception as e:
    print(f"✗ Failed to connect to MongoDB: {str(e)}")
    # Don't exit, let the health check handle it

# RabbitMQ connection with retry logic
def connect_rabbitmq():
    max_retries = 5
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(
                    host="rabbitmq",
                    heartbeat=600,
                    blocked_connection_timeout=300
                )
            )
            channel = connection.channel()
            
            # Declare queues to ensure they exist
            channel.queue_declare(queue="video", durable=True)
            channel.queue_declare(queue="mp3", durable=True)
            
            print("✓ RabbitMQ connection established")
            return connection, channel
        except Exception as e:
            retry_count += 1
            print(f"✗ RabbitMQ connection attempt {retry_count}/{max_retries} failed: {str(e)}")
            if retry_count < max_retries:
                time.sleep(2 ** retry_count)  # Exponential backoff
            else:
                print("✗ Failed to connect to RabbitMQ after all retries")
                return None, None

connection, channel = connect_rabbitmq()


def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@server.route("/health", methods=["GET"])
def health():
    """Health check endpoint"""
    try:
        health_status = {
            "status": "healthy",
            "service": "gateway",
            "dependencies": {}
        }
        
        # Test MongoDB connections
        try:
            mongo_video.db.command('ping')
            mongo_mp3.db.command('ping')
            health_status["dependencies"]["mongodb"] = "healthy"
        except Exception as e:
            health_status["dependencies"]["mongodb"] = f"unhealthy: {str(e)}"
            health_status["status"] = "degraded"
        
        # Test RabbitMQ connection
        try:
            if connection and not connection.is_closed:
                health_status["dependencies"]["rabbitmq"] = "healthy"
            else:
                health_status["dependencies"]["rabbitmq"] = "unhealthy: connection closed"
                health_status["status"] = "degraded"
        except Exception as e:
            health_status["dependencies"]["rabbitmq"] = f"unhealthy: {str(e)}"
            health_status["status"] = "degraded"
        
        # Test auth service
        try:
            import requests
            auth_response = requests.get(
                f"http://{os.environ.get('AUTH_SVC_ADDRESS', 'auth:5000')}/health",
                timeout=5
            )
            if auth_response.status_code == 200:
                health_status["dependencies"]["auth_service"] = "healthy"
            else:
                health_status["dependencies"]["auth_service"] = f"unhealthy: status {auth_response.status_code}"
                health_status["status"] = "degraded"
        except Exception as e:
            health_status["dependencies"]["auth_service"] = f"unhealthy: {str(e)}"
            health_status["status"] = "degraded"
        
        status_code = 200 if health_status["status"] == "healthy" else 503
        return jsonify(health_status), status_code
        
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "service": "gateway",
            "error": str(e)
        }), 503


@server.route("/", methods=["GET"])
def home():
    """Home endpoint"""
    return jsonify({
        "service": "MP3 Converter Gateway",
        "version": "1.0",
        "endpoints": {
            "login": "POST /login",
            "upload": "POST /upload",
            "download": "GET /download?fid=<file_id>",
            "status": "GET /status/<file_id>",
            "health": "GET /health"
        }
    }), 200


@server.route("/login", methods=["POST"])
def login():
    """User login endpoint"""
    try:
        token, err = access.login(request)

        if not err:
            print("✓ Successful login via gateway")
            return token
        else:
            print(f"✗ Login failed via gateway: {err}")
            return err
    except Exception as e:
        print(f"✗ Login error in gateway: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@server.route("/upload", methods=["POST"])
def upload():
    """File upload endpoint"""
    try:
        # Validate token
        access_token, err = validate.token(request)
        if err:
            print("✗ Upload attempt with invalid token")
            return err

        access_data = json.loads(access_token)

        # Check admin privileges
        if not access_data.get("admin"):
            print(f"✗ Unauthorized upload attempt by user: {access_data.get('username')}")
            return jsonify({"error": "Not authorized"}), 401

        # Validate file count
        if len(request.files) != 1:
            return jsonify({"error": "Exactly 1 file required"}), 400

        file_key, file = next(iter(request.files.items()))
        
        # Validate file selection
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400
            
        # Validate file type
        if not allowed_file(file.filename):
            return jsonify({
                "error": f"File type not allowed. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"
            }), 400

        # Secure the filename
        filename = secure_filename(file.filename)
        
        # Validate file size
        file.seek(0, os.SEEK_END)
        file_size = file.tell()
        file.seek(0)
        
        if file_size > server.config['MAX_CONTENT_LENGTH']:
            return jsonify({
                "error": f"File too large. Maximum size: {server.config['MAX_CONTENT_LENGTH'] / (1024*1024):.0f}MB"
            }), 413

        if file_size == 0:
            return jsonify({"error": "File is empty"}), 400

        # Check RabbitMQ connection
        if not connection or connection.is_closed:
            return jsonify({"error": "Message queue unavailable"}), 503

        # Upload file
        err = util.upload(file, fs_videos, channel, access_data)

        if err:
            print(f"✗ Upload error: {err}")
            return err

        print(f"✓ File uploaded successfully by user: {access_data.get('username')}, size: {file_size} bytes")
        return jsonify({
            "message": "Upload successful",
            "filename": filename,
            "size_bytes": file_size,
            "status": "Processing started"
        }), 200
        
    except Exception as e:
        print(f"✗ Upload error: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@server.route("/download", methods=["GET"])
def download():
    """File download endpoint"""
    try:
        # Validate token
        access_token, err = validate.token(request)
        if err:
            return err

        access_data = json.loads(access_token)

        # Check admin privileges
        if not access_data.get("admin"):
            return jsonify({"error": "Not authorized"}), 401

        # Get file ID
        fid_string = request.args.get("fid")
        if not fid_string:
            return jsonify({"error": "File ID (fid) is required"}), 400

        # Validate ObjectId format
        try:
            object_id = ObjectId(fid_string)
        except Exception:
            return jsonify({"error": "Invalid file ID format"}), 400

        try:
            out = fs_mp3s.get(object_id)
            print(f"✓ File downloaded by user: {access_data.get('username')}, fid: {fid_string}")
            return send_file(out, download_name=f'{fid_string}.mp3', as_attachment=True)
        except gridfs.NoFile:
            print(f"✗ File not found for download: {fid_string}")
            return jsonify({"error": "File not found"}), 404
        except Exception as err:
            print(f"✗ Download error: {str(err)}")
            return jsonify({"error": "Internal server error"}), 500

    except Exception as e:
        print(f"✗ Download error: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@server.route("/status/<fid>", methods=["GET"])
def status(fid):
    """Check conversion status of a file"""
    try:
        # Validate token
        access_token, err = validate.token(request)
        if err:
            return err

        access_data = json.loads(access_token)
        if not access_data.get("admin"):
            return jsonify({"error": "Not authorized"}), 401

        # Validate ObjectId format
        try:
            object_id = ObjectId(fid)
        except Exception:
            return jsonify({"error": "Invalid file ID format"}), 400

        # Check if MP3 exists
        try:
            fs_mp3s.get(object_id)
            return jsonify({"status": "completed", "fid": fid}), 200
        except gridfs.NoFile:
            # Check if original video exists
            try:
                fs_videos.get(object_id)
                return jsonify({"status": "processing", "fid": fid}), 200
            except gridfs.NoFile:
                return jsonify({"status": "not_found", "fid": fid}), 404

    except Exception as e:
        print(f"✗ Status check error: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


# Error handlers
@server.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404


@server.errorhandler(405)
def method_not_allowed(error):
    return jsonify({"error": "Method not allowed"}), 405


@server.errorhandler(413)
def request_entity_too_large(error):
    return jsonify({"error": "File too large"}), 413


@server.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500


if __name__ == "__main__":
    print("Starting Gateway Service...")
    server.run(host="0.0.0.0", port=8080, debug=False)