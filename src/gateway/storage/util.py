import pika
import json
from flask import jsonify


def upload(f, fs, channel, access):
    """
    Upload file to GridFS and send message to RabbitMQ
    
    Args:
        f: File object to upload
        fs: GridFS instance
        channel: RabbitMQ channel
        access: Access token data containing user info
    
    Returns:
        None if successful, error tuple if failed
    """
    try:
        # Store file in GridFS
        fid = fs.put(f)
        print(f"✓ File stored in GridFS with ID: {fid}")
        
    except Exception as err:
        print(f"✗ Failed to store file in GridFS: {str(err)}")
        return jsonify({"error": "Failed to store file"}), 500

    # Prepare message for converter service
    message = {
        "video_fid": str(fid),
        "mp3_fid": None,
        "username": access["username"],
    }

    try:
        # Send message to RabbitMQ
        channel.basic_publish(
            exchange="",
            routing_key="video",
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=pika.spec.PERSISTENT_DELIVERY_MODE
            ),
        )
        print(f"✓ Message sent to queue for file: {fid}")
        
    except Exception as err:
        print(f"✗ Failed to send message to queue: {str(err)}")
        # If messaging fails, clean up the uploaded file
        try:
            fs.delete(fid)
            print(f"✓ Cleaned up file {fid} after messaging failure")
        except Exception as cleanup_err:
            print(f"✗ Failed to cleanup file {fid}: {str(cleanup_err)}")
        
        return jsonify({"error": "Failed to queue file for processing"}), 500
    
    # Return None for success
    return None