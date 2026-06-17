# La Salle Foods — Backend (API REST en Java + MySQL)

API REST hecha con **Servlets de Java (Jakarta EE 6, Tomcat 10.1)** sobre **MySQL 8**.
Implementa autenticación propia (BCrypt + JWT), autorización por rol y toda la lógica de
negocio (pedidos, estados, notificaciones). La app SwiftUI consume este backend en `/api`.

## Requisitos

- JDK 17+ y Maven 3.9+ (para compilar)
- Docker (forma más simple de correrlo) **o** Tomcat 10.1 + MySQL 8 instalados

## Variables de entorno

| Variable | Descripción | Default (dev) |
|---|---|---|
| `DB_URL` | URL JDBC de MySQL | `jdbc:mysql://localhost:3306/lasallefoods?...` |
| `DB_USER` | Usuario MySQL | `root` |
| `DB_PASSWORD` | Contraseña MySQL | *(vacío)* |
| `JWT_SECRET` | Secreto para firmar JWT (HS256) | *(dev secret — cambiar en prod)* |
| `INSTITUTIONAL_DOMAIN` | Dominio permitido al registrarse | `@lasallebajio.edu.mx` |
| `SEED_ON_STARTUP` | Sembrar datos demo si la BD está vacía | `true` |

## Correr en local (Docker Compose) — recomendado

```bash
cd backend
docker compose up --build
```

- API: `http://localhost:8080/api`  ·  Health: `http://localhost:8080/api/health`
- En la app SwiftUI, define `API_BASE_URL=http://localhost:8080/api` en el esquema de Xcode
  (Edit Scheme → Run → Arguments → Environment Variables).

## Cuentas demo (contraseña: `LaSalle2026!`)

| Rol | Correo |
|---|---|
| Dueño | `donamary@lasallebajio.edu.mx` |
| Alumno | `alumno@lasallebajio.edu.mx` |

## Compilar el WAR

```bash
cd backend
mvn -DskipTests clean package      # genera target/lasallefoods.war
```

## Esquema de la base

`db/schema.sql` crea las 12 tablas y siembra catálogos. Aplicar manualmente:

```bash
mysql -u root -p < db/schema.sql
```

(En Docker Compose se aplica automáticamente la primera vez.)

## Desplegar en Azure

Edita las variables al inicio de `deploy/azure-deploy.sh` (sobre todo
`MYSQL_ADMIN_PASSWORD` y `JWT_SECRET`) y ejecuta:

```bash
cd backend
bash deploy/azure-deploy.sh
```

Crea Resource Group + ACR (build de la imagen en la nube) + Azure Database for MySQL
Flexible Server + Container App con ingress público en `:8080`, e imprime la URL final.

## Endpoints principales

```
POST /api/auth/register | /login | /refresh    GET /api/auth/me     POST /api/auth/logout
GET/PATCH /api/profile
GET /api/restaurant-categories | /product-categories | /tags
GET /api/restaurants  GET /api/restaurants/{id}  GET /api/restaurants/{id}/products
POST /api/restaurants  PATCH /api/restaurants/{id}  PUT /api/restaurants/{id}/tags
POST /api/products  PATCH/DELETE /api/products/{id}
GET /api/orders  GET /api/orders/{id}  POST /api/orders
POST /api/orders/{id}/cancel  POST /api/orders/{id}/status
GET /api/notifications  POST /api/notifications/{id}/read
GET /api/db/restaurants  GET /api/db/products   (compatibilidad con la app)
GET /api/health
```
