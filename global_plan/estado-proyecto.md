# La Salle Foods — Estado del Proyecto
> Documento de sesión de planificación. Última actualización: 2026-06-16.
> Objetivo: retomar planeación en sesión futura con contexto completo.

---

## Arquitectura general

```
SwiftUI App  ──HTTPS/JSON──▶  Java Servlets (Tomcat/Azure)  ──HTTPS──▶  Supabase
  APIClient.swift                  backend/                         Postgres + PostgREST
  KeychainStore.swift           WAR desplegado en                   Auth (GoTrue)
                                Azure Container Apps                 RLS + funciones SQL
```

- App SwiftUI ya **no usa supabase-swift**. Toda comunicación va por el backend Java.
- Backend Java es gateway/proxy autenticado: reenvía JWT del usuario a PostgREST, agrega `apikey`.
- Toda la lógica de negocio vive en Postgres (RLS, funciones SECURITY DEFINER, triggers).
- Docs técnicas: `backend/docs/` (01 al 07 + archivos `_*.md` de prompts de sesiones).

---

## URLs de producción

| Recurso | URL / Dato |
|---|---|
| Backend Azure | `https://lasallefoods-backend.blackbay-608b8ac9.eastus2.azurecontainerapps.io` |
| Supabase | `https://pftnnkrpufxpzoadbgxu.supabase.co` |
| ACR imagen | `iconicregistry.azurecr.io/lasallefoods-backend:latest` |
| Container App | `lasallefoods-backend` (RG `iconic-rg`, env `managedEnvironment-iconicrg-b19e`) |
| Anon key (pública) | `sb_publishable_0PghU_jyiuPHujQnGCqNVw_KudLnah6` |

---

## Estado actual por capa

### Base de datos (Supabase / Postgres)
- **9 tablas públicas**: `profiles`, `restaurants`, `restaurant_categories`, `restaurant_tags`, `products`, `product_categories`, `tags`, `orders`, `order_lines`, `notifications`.
- **RLS activo** en todas. GRANTs correctos (migración `fix_missing_anon_authenticated_grants` aplicada 2026-06-15).
- **Funciones SQL**: `place_order`, `cancel_order`, `update_order_status`, `mark_notification_read`, `handle_new_user`, `validate_institutional_email`, `prevent_role_change`, `notify_on_order_status_change`, `notify_owner_on_new_order`, `generate_pickup_code`, `set_pickup_code`, `rls_auto_enable`.
- **Catálogo**: 6 `restaurant_categories`, 6 `product_categories`, 3+ `tags`.
- **Datos de prueba**: cuentas `smoke-owner-*` y `smoke-student-*` existen en `auth.users` (inofensivas). Restaurantes y pedidos de seed sesión presentes.
- **Migración pendiente aplicada**: quitar `&is_active=eq.true` del `RestaurantServlet` (fix R6, ver abajo) — ya en código, no requiere migration SQL.

### Backend Java (Tomcat / Azure)
- **Ubicación**: `backend/` — Maven WAR, Java 17, `jakarta.servlet-api 6.0`, Tomcat 10.1.
- **Servlets implementados**: `AuthServlet`, `CatalogServlet`, `RestaurantServlet`, `ProductServlet`, `OrderServlet`, `ProfileServlet`, `NotificationServlet`, `HealthServlet`, `RestProxyServlet`.
- **Filtro**: `LoggingFilter` en `/api/*`.
- **Desplegado y funcionando**: `GET /api/health` → 200.
- **`min-replicas`**: debe establecerse en 1 para evitar cold start en demo. Comando pendiente:
  ```bash
  az containerapp update \
    --name lasallefoods-backend \
    --resource-group iconic-rg \
    --min-replicas 1
  ```

### SwiftUI App
- **APIClient.swift**: base URL apunta a Azure (`https://lasallefoods-backend...`). Keychain para tokens. Retry en 401. Mapeo de errores Postgres en español.
- **SessionStore**: maneja login/registro/logout/perfil/ownedRestaurantID. Listener de `.sessionExpired` → limpia `currentUser` → RootView regresa a Login.
- **CatalogStore**: catálogo, restaurantes, productos, CRUD de owner.
- **OrderStore**: pedidos, notificaciones, RPCs. `clear()` limpiado en logout (RootView `.onChange`).
- **SupabaseManager.swift**: eliminado.

---

## Bugs corregidos en esta sesión (por sesiones delegadas)

| # | Bug | Causa | Fix | Archivos |
|---|---|---|---|---|
| 1 | Grant 42501 en todas las tablas | Faltaban GRANTs base a `anon`/`authenticated` | Migration SQL `fix_missing_anon_authenticated_grants` | Supabase migration |
| 2 | OrderServlet: `order_lines` vacías y `restaurantName` vacío | Select faltaba `restaurants(name),order_lines(*)` | Agregar embeds al select | `OrderServlet.java` |
| 3 | RegisterView: owner sin restaurante asignado tras registro | `addRestaurant()` no guardaba resultado en sesión | Retornar `Restaurant` y llamar `setOwnedRestaurant()` | `RegisterView.swift`, `CatalogStore.swift` |
| 4 | ProfileView: nombre no editable | Sin botón/flujo de edición | Agregar edit flow con alert+TextField | `ProfileView.swift` |
| 5 | 429 email rate limit en registro | Supabase enviaba emails de confirmación, límite SMTP alcanzado | Deshabilitar "Confirm email" en dashboard | Dashboard Supabase (manual) |
| 6 | Alerts faltantes en CartView/OrderDetailView/AdminDashboard | `errorMessage` seteado pero no leído en UI | Agregar `.alert` + leer `errorMessage` | 3 vistas |
| 7 | Session expiry: app rota (isAuthenticated=true con tokens inválidos) | `clearTokens()` limpiaba tokens pero no `currentUser` | `NotificationCenter.sessionExpired` → `SessionStore` limpia `currentUser` | `APIClient.swift`, `SessionStore.swift` |
| 8 | Mapeo de errores Postgres crudos en inglés | `serverErrorMessage` pasaba código técnico al usuario | `friendlyMessage(forCode:)` en `APIClient.swift` para 23505/42501/23502/PGRST* | `APIClient.swift` |
| 9 | Pedidos no se actualizaban en tiempo real (dueño) | Sin mecanismo de refresh | Polling 30s con `.task`/`isCancelled` en `AdminDashboardView` | `AdminDashboardView.swift` |
| 10 | `NotificationsView` abría vacía | `loadNotifications()` nunca se llamaba en `.task` | Agregar `loadNotifications()` antes de `markAllRead()` | `NotificationsView.swift` |
| 11 | Pull-to-refresh faltante | No había `.refreshable` en vistas principales | Agregar en 3 vistas | `OrdersView`, `AdminDashboardView`, `NotificationsView` |
| 12 | Owner nuevo veía pedidos de otros locales | `OrderStore.orders` no se limpiaba en logout (caché en memoria) | `OrderStore.clear()` + `RootView.onChange(isAuthenticated)` | `OrderStore.swift`, `RootView.swift` |
| 13 | R6: dueño no veía su restaurante inactivo vía `/api/restaurants` | `RestaurantServlet` hardcodeaba `&is_active=eq.true`, solapando RLS | Quitar filtro del servlet, dejar que RLS filtre | `RestaurantServlet.java` |
| 14 | `updateStatus`/`cancelByCustomer` fallaban silenciosamente | RPC retorna fila única (`RETURNS orders`), Swift decodificaba como `[OrderStatusRow]` (array) | Cambiar decode a objeto único | `OrderStore.swift` |
| 15 | `addRestaurant` fallaba sin mostrar error, owner llegaba sin local | `nil` silencioso en `RegisterView` | Mostrar error y no hacer `dismiss()` si falla | `RegisterView.swift` |

---

## Documentación generada

| Archivo | Contenido |
|---|---|
| `backend/docs/01-arquitectura.md` | Diagrama, principio pass-through con valor agregado |
| `backend/docs/02-autenticacion.md` | Endpoints auth, flujo JWT, corrección 500 P0001 en email no institucional |
| `backend/docs/03-endpoints.md` | Tabla completa de todos los endpoints |
| `backend/docs/04-estructura-proyecto.md` | Layout Maven, pom.xml, web.xml, ejemplos de código |
| `backend/docs/05-configuracion-despliegue.md` | Env vars, CORS, Docker, Azure (comandos reales) |
| `backend/docs/06-riesgos-y-recomendaciones.md` | Riesgos, dudas, orden de implementación |
| `backend/docs/07-migracion-swiftui.md` | Migración completa, smoke test, sección Azure actualizada |
| `backend/docs/_seed-prompt.md` | Prompt para poblar catálogo con restaurantes reales |
| `backend/docs/_error-ux-audit-prompt.md` | Prompt para auditoría de UX de errores (ya ejecutado) |
| `reglas.md` | Reglas de negocio en español (generadas por sesión auditora) |
| `bugs.md` | Log de bugs reportados |

---

## Auditoría de seguridad (sesión delegada)

Resultado: R1–R21 auditadas. Ver reporte completo en contexto de sesión.

| Prioridad | Regla | Estado |
|---|---|---|
| 🔴 CRÍTICO | R2: cliente puede auto-promover a `owner` en signup vía `raw_user_meta_data` | **Riesgo aceptado** — fix rompe registro de owners legítimos. Mitigado por gate `@lasallebajio.edu.mx`. No aplicar sin rediseñar flujo de roles. |
| 🟡 MEDIO | R6: dueño no veía restaurante inactivo vía API | **Corregido** — fix #13 arriba |
| 🟢 BAJO | `place_order` acepta carrito vacío | **Pendiente** — agregar `IF jsonb_array_length(p_items) = 0 THEN RAISE EXCEPTION` en función SQL |

---

## Pendientes activos

### Urgentes para demo
- [ ] `az containerapp update --min-replicas 1` — evitar cold start (comando listo arriba).
- [ ] Verificar build y run en Xcode/simulador (Mac) — no probado en este entorno (Linux).
- [ ] Bug "owner registrado sigue sin ver su local" — sesión delegada activa (fix #15 en RegisterView, pero falta confirmación si es causa A o B en DB).

### Funcionalidad
- [ ] Fix LOW auditoría: validar `p_items` no vacío en `place_order` SQL.
- [ ] `catalog.errorMessage` nunca leído en vistas de owner (ProductFormView, AdminDashboard para productos) — huecos 4 y 6 del audit UX.
- [ ] `loadOrders`/`loadCatalog` silent fails (errores de red al cargar sin conexión no muestran nada).

### Opcionales / post-entrega
- [ ] `PUT /api/restaurants/{id}/tags` — endpoint listo en backend, sin caller en SwiftUI.
- [ ] `/api/home` endpoint agregado (catálogo + tags en 1 llamada).
- [ ] Hardening DB: `SET search_path` en 4 funciones, `leaked_password_protection`, revoke EXECUTE de funciones trigger en anon/authenticated.

---

## Credenciales de cuentas de prueba (owners seed)

Todos usan contraseña: `LaSalle2026!`
Email pattern: `<slug>@lasallebajio.edu.mx`

Generados por sesión de seed — ver reporte de esa sesión para lista exacta de slugs.
Cuentas `smoke-owner-*` y `smoke-student-*` también existen (password desconocida, generada en smoke test).

---

## Cómo retomar en sesión nueva

1. Leer este archivo (`global_plan/estado-proyecto.md`).
2. Leer `reglas.md` — reglas de negocio completas.
3. Leer `backend/docs/03-endpoints.md` — mapa de todos los endpoints.
4. Revisar `bugs.md` — bugs reportados y su estado.
5. Para cualquier tarea nueva: generar prompt auto-contenido tipo "una sesión = una tarea", referenciando archivos concretos con líneas cuando aplique.
6. URL base para curl contra producción: `https://lasallefoods-backend.blackbay-608b8ac9.eastus2.azurecontainerapps.io/api`.
