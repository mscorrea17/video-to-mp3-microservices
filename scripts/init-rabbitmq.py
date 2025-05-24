#!/usr/bin/env python3

import pika
import time
import sys

def init_rabbitmq():
    """Inicializa las colas de RabbitMQ"""
    max_retries = 30
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            # Conectar a RabbitMQ
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(host='localhost')
            )
            channel = connection.channel()
            
            # Declarar las colas
            channel.queue_declare(queue='video', durable=True)
            channel.queue_declare(queue='mp3', durable=True)
            
            print("✅ Colas de RabbitMQ inicializadas correctamente:")
            print("   - Cola 'video' creada")
            print("   - Cola 'mp3' creada")
            
            connection.close()
            return True
            
        except Exception as e:
            retry_count += 1
            print(f"❌ Intento {retry_count}/{max_retries} fallido: {e}")
            if retry_count < max_retries:
                print("⏳ Reintentando en 2 segundos...")
                time.sleep(2)
            else:
                print("💥 No se pudo conectar a RabbitMQ después de todos los intentos")
                return False

if __name__ == "__main__":
    success = init_rabbitmq()
    sys.exit(0 if success else 1)