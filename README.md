# Conversor de Video a MP3

Aplicación web para convertir videos a archivos MP3 utilizando arquitectura de microservicios. El proyecto permite a los usuarios subir videos, procesarlos de forma asíncrona y recibir notificaciones cuando la conversión esté completa.

## Funcionalidades

- Autenticación de usuarios con JWT
- Carga y conversión de videos a MP3
- Sistema de notificaciones por email
- Procesamiento asíncrono de archivos
- API REST para todas las operaciones

## Arquitectura del Sistema

El sistema está dividido en varios microservicios independientes:

### Auth Service (Puerto 5000)
Gestiona la autenticación de usuarios mediante tokens JWT. Utiliza MySQL para almacenar credenciales y validar el acceso a la aplicación.

### Gateway Service (Puerto 8080) 
Actúa como punto de entrada único para todas las peticiones. Coordina la carga de videos, validación de tokens y descarga de archivos procesados. Los archivos se almacenan usando MongoDB GridFS.

### Converter Service
Procesa la conversión de videos a formato MP3 utilizando FFmpeg. Funciona de manera asíncrona consumiendo trabajos desde RabbitMQ.

### Notification Service
Envía notificaciones por correo electrónico cuando las conversiones han finalizado. También consume mensajes de RabbitMQ para conocer el estado de los trabajos.

## Stack Tecnológico

- **Lenguaje**: Python con Flask
- **Contenedores**: Docker + Kubernetes
- **Colas de mensajes**: RabbitMQ
- **Bases de datos**: MySQL, MongoDB
- **Procesamiento**: MoviePy + FFmpeg

## Requisitos del Sistema

- Docker y Docker Compose
- Kubernetes (Minikube para desarrollo local)
- Python 3.10+
- kubectl

## Instalación y Configuración

### Clonar el repositorio
```bash
git clone <tu-repositorio-url>
cd video-to-mp3-microservices
```

### Configuración de variables de entorno
Los archivos de configuración están ubicados en el directorio `k8s/`. Es necesario actualizar:
- Credenciales de Gmail para el servicio de notificaciones
- Secretos JWT para autenticación
- Credenciales de acceso a bases de datos

### Desarrollo Local
Para ejecutar la aplicación localmente usando Docker Compose:
```bash
# Ejecutar toda la aplicación
docker-compose up -d

# Ver logs
docker-compose logs -f
```

### Despliegue en Producción
Para desplegar en un cluster de Kubernetes:
```bash
# Construir imágenes
chmod +x scripts/build.sh
./scripts/build.sh

# Desplegar en Kubernetes
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## Uso de la API

### Autenticación
```bash
curl -X POST http://localhost:8080/login \
  -u admin@email.com:admin123
```

### Carga de archivos
```bash
curl -X POST http://localhost:8080/upload \
  -H "Authorization: Bearer <tu-jwt-token>" \
  -F "file=@video.mp4"
```

### Descarga de archivos
```bash
curl -X GET "http://localhost:8080/download?fid=<file-id>" \
  -H "Authorization: Bearer <tu-jwt-token>" \
  --output audio.mp3
```

## Flujo de Trabajo

1. **Usuario se autentica** → Recibe JWT token
2. **Usuario sube video** → Se almacena en MongoDB
3. **Gateway envía mensaje** → RabbitMQ (cola 'video')
4. **Converter procesa** → Convierte video a MP3
5. **Converter envía mensaje** → RabbitMQ (cola 'mp3')
6. **Notification envía email** → Usuario recibe ID del archivo
7. **Usuario descarga MP3** → Usando el file ID

## Resolución de Problemas

### Visualizar logs de servicios
```bash
# Docker Compose
docker-compose logs [service-name]

# Kubernetes
kubectl logs -f deployment/[service-name]
```

### Acceso a RabbitMQ Management
- Management UI: http://localhost:15672
- User: auth_user / Pass: Auth123

### Verificación de bases de datos
```bash
# MySQL
docker exec -it [mysql-container] mysql -u auth_user -p auth

# MongoDB
docker exec -it [mongo-container] mongosh
```

## Estructura del Proyecto

```
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
```

## Configuración de Notificaciones por Email

Para habilitar las notificaciones automáticas:

1. Activar la autenticación de dos factores en Gmail
2. Generar una contraseña de aplicación específica
3. Configurar las credenciales en `notification-deploy.yaml`:
   ```yaml
   GMAIL_ADDRESS: "tu-email@gmail.com"
   GMAIL_PASSWORD: "tu-app-password"
   ```

## Contribuciones

Las contribuciones son bienvenidas. Para contribuir:

1. Hacer fork del repositorio
2. Crear una rama para la nueva funcionalidad
3. Realizar commit de los cambios
4. Enviar pull request con descripción detallada

## Licencia

Este proyecto está disponible bajo la Licencia MIT.

## Información Adicional
