# La Salle Foods — Estado del Proyecto
> Documento de sesión de planificación. Última actualización: 2026-06-17.
> Objetivo: retomar planeación en sesión futura con contexto completo.

---

## Arquitectura general (Java + MySQL)

```
SwiftUI App  ──HTTPS/JSON──▶  API REST Java (Servlets/Tomcat)  ──JDBC──▶  MySQL 8
  APIClient.swift                  backend/                            (12 tablas)
  KeychainStore.swift
```

- El backend implementa todo por su cuenta (rúbrica: "API REST con Java y MySQL"):
  - **Autenticación propia**: registro/login/refresh con BCrypt (`org.mindrot:jbcrypt`)
    y JWT HS256 hecho a mano (`auth/Jwt.java`). Refresh tokens opacos en MySQL.
  - **Autorización** en código Java: ver `web/ApiServlet` (`requireOwner`,
    `requireStudent`) y validaciones por dueño/alumno en los repositorios.
  - **Lógica de negocio** en Java: `repo/OrderRepository` (folio `LSF-<seq>`, código de
    recogida, transiciones de estado estrictas, notificaciones a dueño/alumno), etc.
  - **Acceso a datos** vía JDBC + pool HikariCP (`db/Db.java`).
- `APIClient.baseURL` es configurable con la variable `API_BASE_URL` (esquema de Xcode o
  Info.plist). En Debug apunta a `http://localhost:8080/api`.
- Esquema y datos: `backend/db/schema.sql` (12 tablas + catálogos). Datos demo sembrados
  al arrancar por `db/Seeder.java` (idempotente).
- Stack local: `backend/docker-compose.yml` (`docker compose up --build`).
- Despliegue Azure (opcional): `backend/deploy/azure-deploy.sh`.

---

## Estado actual por capa

### Base de datos (MySQL 8)
- **12 tablas** (`backend/db/schema.sql`): `users`, `profiles`, `refresh_tokens`,
  `restaurant_categories`, `product_categories`, `tags`, `restaurants`, `restaurant_tags`,
  `products`, `orders`, `order_lines`, `notifications`.
- IDs de dominio como `CHAR(36)` (UUID generado por la app). Tiempos en UTC (`DATETIME(3)`).
- Folio del pedido: columna `seq` AUTO_INCREMENT (arranca en 2048) → `LSF-<seq>`.
- Constraints/llaves foráneas y CHECKs hacen cumplir reglas (1 local por dueño, precios ≥ 0,
  color hex válido, etc.). La autorización fina vive en Java.
- **Catálogo sembrado**: 6 `restaurant_categories`, 5 `product_categories` (coinciden con el
  enum `ProductCategory`), 5 `tags`.
- **Datos demo** (`db/Seeder.java`, contraseña `LaSalle2026!`): dueño
  `donamary@lasallebajio.edu.mx` con local "Tortas Doña Mary" + 5 productos, y alumno
  `alumno@lasallebajio.edu.mx`.

### Backend Java (Tomcat)
- **Ubicación**: `backend/` — Maven WAR, Java 17, `jakarta.servlet-api 6.0`, Tomcat 10.1.
- **Dependencias**: `mysql-connector-j`, `HikariCP`, `jbcrypt`, `slf4j-nop`.
- **Servlets**: `AuthServlet` (auth propia), `CatalogServlet`, `RestaurantServlet`,
  `ProductServlet`, `OrderServlet`, `ProfileServlet`, `NotificationServlet`, `HealthServlet`,
  `DbServlet` (compat `/api/db/*`).
- **Filtros**: `AuthFilter` (valida JWT y expone usuario) + `LoggingFilter` en `/api/*`.
- **Arranque**: `StartupListener` fija TZ=UTC y siembra datos demo.
- **Verificado localmente** (Docker MySQL + Tomcat): health, login, pedido (folio LSF-2048),
  transiciones de estado, notificaciones, cancelación, validación de correo institucional,
  edición de local y etiquetas. Todo OK.

### SwiftUI App
- **APIClient.swift**: base URL configurable (`API_BASE_URL`; Debug → `http://localhost:8080/api`).
  Keychain para tokens. Retry en 401. Mapeo de errores del backend a mensajes en español.
- **SessionStore**: maneja login/registro/logout/perfil/ownedRestaurantID. Listener de
  `.sessionExpired` → limpia `currentUser` → RootView regresa a Login.
- **CatalogStore**: catálogo, restaurantes, productos, CRUD de owner (incl. editar local y etiquetas).
- **OrderStore**: pedidos y notificaciones. `clear()` en logout (RootView `.onChange`).
- **Info.plist** (`LaSalleFoods-Info.plist`): excepción ATS `NSAllowsLocalNetworking` para
  permitir HTTP a `localhost` durante el desarrollo/demo.

---

## Cómo correr (local)

1. Backend + DB: `cd backend && docker compose up --build` (expone `http://localhost:8080/api`).
2. App: abrir el proyecto en Xcode y **Run** (Debug) en el simulador. La app apunta a local
   automáticamente vía `API_BASE_URL` en el Info.plist.
3. Cuentas demo (password `LaSalle2026!`):
   - Dueño: `donamary@lasallebajio.edu.mx`
   - Alumno: `alumno@lasallebajio.edu.mx`
4. Registro: solo se aceptan correos `@lasallebajio.edu.mx`.

---

## Pendientes / opcionales

- [ ] Desplegar el backend Java+MySQL a Azure para la entrega (`backend/deploy/azure-deploy.sh`)
      y actualizar la URL de producción en `APIClient.swift` (default Release).
- [ ] `catalog.errorMessage` no leído en algunas vistas de owner (ProductFormView).
- [ ] `loadOrders`/`loadCatalog`: errores de red al cargar sin conexión no muestran nada.
- [ ] `/api/home` (catálogo + tags en 1 llamada) — disponible en backend, sin caller en SwiftUI.

---

## Cómo retomar en sesión nueva

1. Leer este archivo (`global_plan/estado-proyecto.md`).
2. Leer `reglas.md` — reglas de negocio.
3. Leer `backend/README.md` — setup local, endpoints y despliegue.
4. Revisar `bugs.md` — bugs reportados y su estado.
