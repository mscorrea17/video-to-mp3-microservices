import smtplib
import os
import json
from email.message import EmailMessage


def notification(message):
    try:
        message = json.loads(message)
        mp3_fid = message["mp3_fid"]
        sender_address = os.environ.get("GMAIL_ADDRESS")
        sender_password = os.environ.get("GMAIL_PASSWORD")
        receiver_address = message["username"]

        msg = EmailMessage()
        msg["Subject"] = "MP3 Download"
        msg["From"] = sender_address
        msg["To"] = receiver_address

        msg.set_content(
            f"""
            Hi {receiver_address}!
            Your MP3 file is ready for download. The file ID is: {mp3_fid}
            
            Use the file ID to download your MP3 file from our gateway service.
            
            Thanks for using our service!
            """
        )

        # Gmail SMTP configuration
        session = smtplib.SMTP("smtp.gmail.com", 587)
        session.starttls()
        session.login(sender_address, sender_password)
        session.send_message(msg, sender_address, receiver_address)
        session.quit()
        print("Mail sent")

    except Exception as err:
        print(err)
        return err