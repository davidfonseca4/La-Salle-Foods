-- =====================================================================
-- La Salle Foods — Consultas de verificación (Azure MySQL / TablePlus)
-- Ejecuta con Cmd+R. Refresca después de cambiar algo en la app.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. RESUMEN RÁPIDO (¿todo tiene datos?)
-- ---------------------------------------------------------------------
SELECT 'users'                 AS tabla, COUNT(*) AS filas FROM users
UNION ALL SELECT 'profiles',              COUNT(*) FROM profiles
UNION ALL SELECT 'refresh_tokens',        COUNT(*) FROM refresh_tokens
UNION ALL SELECT 'restaurant_categories', COUNT(*) FROM restaurant_categories
UNION ALL SELECT 'product_categories',    COUNT(*) FROM product_categories
UNION ALL SELECT 'tags',                  COUNT(*) FROM tags
UNION ALL SELECT 'restaurants',           COUNT(*) FROM restaurants
UNION ALL SELECT 'restaurant_tags',       COUNT(*) FROM restaurant_tags
UNION ALL SELECT 'products',              COUNT(*) FROM products
UNION ALL SELECT 'orders',                COUNT(*) FROM orders
UNION ALL SELECT 'order_lines',           COUNT(*) FROM order_lines
UNION ALL SELECT 'notifications',         COUNT(*) FROM notifications;


-- ---------------------------------------------------------------------
-- 1. USUARIOS Y PERFILES (Auth / registro)
-- ---------------------------------------------------------------------

-- Cuentas demo y roles
SELECT u.email, p.full_name, p.role, u.created_at
FROM users u
JOIN profiles p ON p.id = u.id
ORDER BY p.role, u.email;

-- Solo dueños
SELECT u.email, p.full_name
FROM users u
JOIN profiles p ON p.id = u.id
WHERE p.role = 'owner';

-- Solo alumnos
SELECT u.email, p.full_name
FROM users u
JOIN profiles p ON p.id = u.id
WHERE p.role = 'student';

-- Sesiones activas (refresh tokens no expirados)
SELECT u.email, rt.token, rt.expires_at, rt.created_at
FROM refresh_tokens rt
JOIN users u ON u.id = rt.user_id
WHERE rt.expires_at > UTC_TIMESTAMP()
ORDER BY rt.created_at DESC;


-- ---------------------------------------------------------------------
-- 2. CATÁLOGOS FIJOS (6 categorías local + 5 producto + 5 tags)
-- ---------------------------------------------------------------------

SELECT id, name FROM restaurant_categories ORDER BY id;
SELECT id, name, sort_order FROM product_categories ORDER BY sort_order;
SELECT id, name FROM tags ORDER BY id;


-- ---------------------------------------------------------------------
-- 3. RESTAURANTES (CRUD local + etiquetas)
-- ---------------------------------------------------------------------

-- Locales con dueño y categoría
SELECT
  r.name AS local,
  rc.name AS categoria,
  r.location,
  r.is_open AS abierto,
  r.is_active AS activo,
  u.email AS dueno,
  p.full_name AS nombre_dueno,
  r.prep_time_min,
  r.prep_time_max,
  r.cover_color
FROM restaurants r
JOIN restaurant_categories rc ON rc.id = r.category_id
JOIN profiles p ON p.id = r.owner_id
JOIN users u ON u.id = p.id;

-- Etiquetas de cada local
SELECT
  r.name AS local,
  GROUP_CONCAT(t.name ORDER BY t.name SEPARATOR ', ') AS etiquetas
FROM restaurants r
LEFT JOIN restaurant_tags rt ON rt.restaurant_id = r.id
LEFT JOIN tags t ON t.id = rt.tag_id
GROUP BY r.id, r.name;


-- ---------------------------------------------------------------------
-- 4. PRODUCTOS (CRUD productos)
-- ---------------------------------------------------------------------

-- Menú completo por local
SELECT
  r.name AS local,
  pc.name AS categoria,
  p.name AS producto,
  p.price,
  p.is_available AS disponible,
  p.is_popular AS popular,
  p.description
FROM products p
JOIN restaurants r ON r.id = p.restaurant_id
JOIN product_categories pc ON pc.id = p.category_id
ORDER BY r.name, pc.sort_order, p.name;

-- Productos agotados
SELECT r.name AS local, p.name, p.price
FROM products p
JOIN restaurants r ON r.id = p.restaurant_id
WHERE p.is_available = 0;

-- Productos populares
SELECT r.name AS local, p.name, p.price
FROM products p
JOIN restaurants r ON r.id = p.restaurant_id
WHERE p.is_popular = 1;


-- ---------------------------------------------------------------------
-- 5. PEDIDOS (Create pedido + estados en tiempo real)
-- ---------------------------------------------------------------------

-- Pedidos con folio legible (LSF-<seq>)
SELECT
  CONCAT('LSF-', o.seq) AS folio,
  o.status,
  o.pickup_code,
  o.payment_method,
  r.name AS local,
  cu.email AS alumno,
  o.created_at
FROM orders o
JOIN restaurants r ON r.id = o.restaurant_id
JOIN profiles cp ON cp.id = o.customer_id
JOIN users cu ON cu.id = cp.id
ORDER BY o.created_at DESC;

-- Conteo por estado (ideal para ver cambios del dueño)
SELECT status, COUNT(*) AS total
FROM orders
GROUP BY status
ORDER BY FIELD(status, 'pending','preparing','ready','completed','cancelled');

-- Pedidos pendientes / en curso (los que deberían moverse en la demo)
SELECT CONCAT('LSF-', seq) AS folio, status, pickup_code, created_at
FROM orders
WHERE status IN ('pending','preparing','ready')
ORDER BY created_at DESC;

-- Detalle de un pedido (renglones + total calculado)
SELECT
  CONCAT('LSF-', o.seq) AS folio,
  o.status,
  ol.product_name,
  ol.quantity,
  ol.unit_price,
  (ol.quantity * ol.unit_price) AS subtotal,
  ol.notes
FROM orders o
JOIN order_lines ol ON ol.order_id = o.id
ORDER BY o.created_at DESC, ol.product_name;

-- Total por pedido (debe coincidir con lo que ve la app)
SELECT
  CONCAT('LSF-', o.seq) AS folio,
  o.status,
  SUM(ol.quantity * ol.unit_price) AS total
FROM orders o
JOIN order_lines ol ON ol.order_id = o.id
GROUP BY o.id, o.seq, o.status
ORDER BY o.created_at DESC;


-- ---------------------------------------------------------------------
-- 6. NOTIFICACIONES (avisos automáticos al cambiar estado)
-- ---------------------------------------------------------------------

-- Todas las notificaciones con destinatario
SELECT
  u.email AS destinatario,
  p.role,
  n.title,
  n.message,
  n.related_status,
  n.is_read AS leida,
  CONCAT('LSF-', o.seq) AS pedido,
  n.created_at
FROM notifications n
JOIN profiles p ON p.id = n.recipient_id
JOIN users u ON u.id = p.id
JOIN orders o ON o.id = n.order_id
ORDER BY n.created_at DESC;

-- Notificaciones sin leer (badge de campana en la app)
SELECT u.email, n.title, n.message, n.created_at
FROM notifications n
JOIN users u ON u.id = n.recipient_id
WHERE n.is_read = 0
ORDER BY n.created_at DESC;

-- Notificaciones generadas por cambio de estado
SELECT related_status, COUNT(*) AS total
FROM notifications
WHERE related_status IS NOT NULL
GROUP BY related_status;


-- ---------------------------------------------------------------------
-- 7. CONSULTAS “DEMO EN VIVO” — usa estas mientras pruebas la app
-- ---------------------------------------------------------------------

-- A) Antes/después de cambiar estado en el panel del dueño:
--    Ejecuta, cambia estado en la app, ejecuta otra vez (Cmd+R).
SELECT CONCAT('LSF-', seq) AS folio, status, pickup_code, created_at
FROM orders
ORDER BY created_at DESC
LIMIT 5;

-- B) Después de crear un pedido como alumno:
SELECT CONCAT('LSF-', seq) AS folio, status, pickup_code
FROM orders
ORDER BY created_at DESC
LIMIT 1;

-- C) Después de editar un producto en la app:
SELECT name, price, is_available, is_popular
FROM products
ORDER BY created_at DESC
LIMIT 5;

-- D) Después de editar el local (nombre, abierto, etiquetas):
SELECT name, location, is_open, description
FROM restaurants;

-- E) Después de registrar un usuario nuevo:
SELECT u.email, p.full_name, p.role, u.created_at
FROM users u
JOIN profiles p ON p.id = u.id
ORDER BY u.created_at DESC
LIMIT 5;


-- ---------------------------------------------------------------------
-- 8. INTEGRIDAD (sanity checks — deberían dar 0 filas si todo está bien)
-- ---------------------------------------------------------------------

-- Pedidos sin renglones (no debería haber)
SELECT o.id, CONCAT('LSF-', o.seq) AS folio
FROM orders o
LEFT JOIN order_lines ol ON ol.order_id = o.id
WHERE ol.id IS NULL;

-- Dueños sin local (excepto recién registrados sin completar flujo)
SELECT u.email, p.full_name
FROM profiles p
JOIN users u ON u.id = p.id
LEFT JOIN restaurants r ON r.owner_id = p.id
WHERE p.role = 'owner' AND r.id IS NULL;

-- Productos huérfanos (no debería haber)
SELECT p.name
FROM products p
LEFT JOIN restaurants r ON r.id = p.restaurant_id
WHERE r.id IS NULL;
