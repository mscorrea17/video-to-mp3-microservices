Video to MP3 Converter - Microservices Architecture
Este proyecto implementa una aplicación de conversión de video a MP3 usando arquitectura de microservicios, basado en el curso de FreeCodeCamp.

🎯 Características
Autenticación JWT: Sistema seguro de login con tokens
Conversión de Video: Convierte videos subidos a formato MP3
Notificaciones: Envía emails cuando la conversión está lista
Arquitectura de Microservicios: Servicios independientes y escalables
Comunicación Asíncrona: Usa RabbitMQ para desacoplamiento
🏗️ Arquitectura
La aplicación está compuesta por 4 microservicios principales:

1. Auth Service (Puerto 5000)
Maneja autenticación de usuarios
Genera y valida tokens JWT
Base de datos: MySQL
2. Gateway Service (Puerto 8080)
Punto de entrada principal de la API
Maneja upload de videos y download de MP3s
Valida tokens JWT
Almacena archivos en MongoDB (GridFS)
3. Converter Service
Convierte videos a MP3 usando MoviePy
Consume mensajes de RabbitMQ
Procesa archivos de forma asíncrona
4. Notification Service
Envía notificaciones por email
Informa cuando la conversión está lista
Consume mensajes de RabbitMQ
🛠️ Tecnologías
Backend: Python + Flask
Bases de datos: MySQL, MongoDB
Mensajería: RabbitMQ
Contenedores: Docker
Orquestación: Kubernetes
Conversión: MoviePy + FFmpeg
📋 Prerequisitos
Docker y Docker Compose
Kubernetes (Minikube para desarrollo local)
Python 3.10+
kubectl
🚀 Instalación y Configuración
1. Clonar el repositorio
bash
git clone <tu-repositorio-url>
cd video-to-mp3-microservices
2. Configurar variables de entorno
Edita los archivos de configuración en k8s/ para configurar:

Credenciales de Gmail para notificaciones
Secretos JWT
Credenciales de base de datos
3. Desarrollo Local (Docker Compose)
bash
# Ejecutar toda la aplicación
docker-compose up -d

# Ver logs
docker-compose logs -f
4. Producción (Kubernetes)
bash
# Construir imágenes
chmod +x scripts/build.sh
./scripts/build.sh

# Desplegar en Kubernetes
chmod +x scripts/deploy.sh
./scripts/deploy.sh
📝 Uso de la API
1. Login
bash
curl -X POST http://localhost:8080/login \
  -u admin@email.com:admin123
2. Upload Video
bash
curl -X POST http://localhost:8080/upload \
  -H "Authorization: Bearer <tu-jwt-token>" \
  -F "file=@video.mp4"
3. Download MP3
bash
curl -X GET "http://localhost:8080/download?fid=<file-id>" \
  -H "Authorization: Bearer <tu-jwt-token>" \
  --output audio.mp3
🔄 Flujo de la Aplicación
Usuario se autentica → Recibe JWT token
Usuario sube video → Se almacena en MongoDB
Gateway envía mensaje → RabbitMQ (cola 'video')
Converter procesa → Convierte video a MP3
Converter envía mensaje → RabbitMQ (cola 'mp3')
Notification envía email → Usuario recibe ID del archivo
Usuario descarga MP3 → Usando el file ID
🐛 Debugging
Ver logs de servicios
bash
# Docker Compose
docker-compose logs [service-name]

# Kubernetes
kubectl logs -f deployment/[service-name]
Verificar estado de RabbitMQ
Management UI: http://localhost:15672
User: auth_user / Pass: Auth123
Verificar conexiones de base de datos
bash
# MySQL
docker exec -it [mysql-container] mysql -u auth_user -p auth

# MongoDB
docker exec -it [mongo-container] mongosh
📁 Estructura del Proyecto
video-to-mp3-microservices/
├── src/
│   ├── auth/           # Servicio de autenticación
│   ├── gateway/        # Gateway principal
│   ├── converter/      # Servicio de conversión
│   └── notification/   # Servicio de notificaciones
├── k8s/               # Manifests de Kubernetes
├── scripts/           # Scripts de build y deploy
├── docker-compose.yml # Configuración para desarrollo
└── README.md
🔧 Configuración de Gmail
Para las notificaciones por email:

Habilita autenticación de 2 factores en Gmail
Genera una "App Password"
Configura las variables en notification-deploy.yaml:
yaml
GMAIL_ADDRESS: "tu-email@gmail.com"
GMAIL_PASSWORD: "tu-app-password"
🤝 Contribuir
Fork el proyecto
Crea una rama para tu feature (git checkout -b feature/AmazingFeature)
Commit tus cambios (git commit -m 'Add some AmazingFeature')
Push a la rama (git push origin feature/AmazingFeature)
Abre un Pull Request
📄 Licencia
Este proyecto está bajo la Licencia MIT. Ver el archivo LICENSE para más detalles.

🎓 Créditos
Basado en el curso "Microservices and Software System Design" de FreeCodeCamp, impartido por Georgio de Kantan Coding.

🆘 Soporte
Si tienes problemas o preguntas:

Revisa la sección de debugging
Verifica los logs de los servicios
Abre un issue en el repositorio
