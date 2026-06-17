-- =====================================================================
-- La Salle Foods — Esquema MySQL
-- API REST en Java (servlets) + MySQL. La autenticación, la autorización
-- y la lógica de negocio viven en el backend Java; este archivo define el
-- almacenamiento.
--
-- Convenciones:
--   * Los identificadores de entidades de dominio son UUID (CHAR(36)),
--     generados por la aplicación.
--   * Las marcas de tiempo se guardan en UTC (DATETIME(3)).
--   * Catálogos fijos (categorías, etiquetas) usan enteros autoincrementales.
--
-- Ejecutar:  mysql -u root -p < schema.sql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS lasallefoods
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lasallefoods;

-- Asegura que los acentos del seed (ej. "Lo más pedido", "Cafetería") se
-- almacenen como UTF-8 real y no doble-codificados al importar este archivo.
SET NAMES utf8mb4;

-- Orden de borrado respetando llaves foráneas (para reinicios limpios).
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS order_lines;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS restaurant_tags;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS product_categories;
DROP TABLE IF EXISTS restaurant_categories;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS profiles;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- 1. users — credenciales de acceso (correo + hash de contraseña)
-- ---------------------------------------------------------------------
CREATE TABLE users (
  id            CHAR(36)     NOT NULL,
  email         VARCHAR(255) NOT NULL,
  password_hash VARCHAR(100) NOT NULL,
  created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. profiles — datos públicos del usuario (nombre y rol). 1:1 con users.
--    El rol es inmutable a nivel de aplicación.
-- ---------------------------------------------------------------------
CREATE TABLE profiles (
  id         CHAR(36)                     NOT NULL,
  full_name  VARCHAR(150)                 NOT NULL,
  role       ENUM('student','owner')      NOT NULL DEFAULT 'student',
  created_at DATETIME(3)                  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  CONSTRAINT fk_profiles_user FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. refresh_tokens — tokens opacos de renovación de sesión
-- ---------------------------------------------------------------------
CREATE TABLE refresh_tokens (
  token      CHAR(36)    NOT NULL,
  user_id    CHAR(36)    NOT NULL,
  expires_at DATETIME(3) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (token),
  KEY idx_refresh_user (user_id),
  CONSTRAINT fk_refresh_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. restaurant_categories — catálogo de tipos de local (nombre único)
-- ---------------------------------------------------------------------
CREATE TABLE restaurant_categories (
  id   INT          NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_restaurant_categories_name (name)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. product_categories — catálogo de categorías de producto (nombre único)
--    Los nombres coinciden EXACTAMENTE con el enum ProductCategory de la app.
-- ---------------------------------------------------------------------
CREATE TABLE product_categories (
  id         INT          NOT NULL AUTO_INCREMENT,
  name       VARCHAR(100) NOT NULL,
  sort_order INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_product_categories_name (name)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. tags — etiquetas globales (nombre único)
-- ---------------------------------------------------------------------
CREATE TABLE tags (
  id   INT          NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tags_name (name)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. restaurants — locales del campus
-- ---------------------------------------------------------------------
CREATE TABLE restaurants (
  id            CHAR(36)      NOT NULL,
  owner_id      CHAR(36)      NOT NULL,
  category_id   INT           NOT NULL,
  name          VARCHAR(150)  NOT NULL,
  description   VARCHAR(500)  NOT NULL DEFAULT '',
  location      VARCHAR(200)  NOT NULL DEFAULT '',
  symbol        VARCHAR(100)  NOT NULL DEFAULT 'storefront.fill',
  cover_color   CHAR(7)       NOT NULL DEFAULT '#FF7426',
  rating        DECIMAL(2,1)  NOT NULL DEFAULT 0.0,
  review_count  INT           NOT NULL DEFAULT 0,
  prep_time_min INT           NOT NULL DEFAULT 8,
  prep_time_max INT           NOT NULL DEFAULT 15,
  is_open       TINYINT(1)    NOT NULL DEFAULT 1,
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  created_at    DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  -- Cada dueño solo puede tener un restaurante.
  UNIQUE KEY uq_restaurants_owner (owner_id),
  KEY idx_restaurants_active (is_active),
  CONSTRAINT fk_restaurants_owner    FOREIGN KEY (owner_id)    REFERENCES profiles(id)              ON DELETE CASCADE,
  CONSTRAINT fk_restaurants_category FOREIGN KEY (category_id) REFERENCES restaurant_categories(id),
  CONSTRAINT chk_restaurants_rating       CHECK (rating BETWEEN 0 AND 5),
  CONSTRAINT chk_restaurants_reviews      CHECK (review_count >= 0),
  CONSTRAINT chk_restaurants_prep_min     CHECK (prep_time_min > 0),
  CONSTRAINT chk_restaurants_cover_color  CHECK (cover_color REGEXP '^#[0-9A-Fa-f]{6}$')
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. restaurant_tags — relación N:M restaurante–etiqueta
-- ---------------------------------------------------------------------
CREATE TABLE restaurant_tags (
  restaurant_id CHAR(36) NOT NULL,
  tag_id        INT      NOT NULL,
  PRIMARY KEY (restaurant_id, tag_id),
  CONSTRAINT fk_rtags_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
  CONSTRAINT fk_rtags_tag        FOREIGN KEY (tag_id)        REFERENCES tags(id)        ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. products — platillos/bebidas de cada local
-- ---------------------------------------------------------------------
CREATE TABLE products (
  id            CHAR(36)      NOT NULL,
  restaurant_id CHAR(36)      NOT NULL,
  category_id   INT           NOT NULL,
  name          VARCHAR(150)  NOT NULL,
  description   VARCHAR(500)  NOT NULL DEFAULT '',
  price         DECIMAL(10,2) NOT NULL DEFAULT 0,
  symbol        VARCHAR(100)  NOT NULL DEFAULT 'fork.knife',
  is_available  TINYINT(1)    NOT NULL DEFAULT 1,
  is_popular    TINYINT(1)    NOT NULL DEFAULT 0,
  created_at    DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_products_restaurant (restaurant_id),
  CONSTRAINT fk_products_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id)        ON DELETE CASCADE,
  CONSTRAINT fk_products_category   FOREIGN KEY (category_id)   REFERENCES product_categories(id),
  CONSTRAINT chk_products_price CHECK (price >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 10. orders — pedidos
--     `seq` autoincremental alimenta el folio legible LSF-<seq>.
-- ---------------------------------------------------------------------
CREATE TABLE orders (
  id             CHAR(36)                                              NOT NULL,
  seq            BIGINT                                                NOT NULL AUTO_INCREMENT,
  customer_id    CHAR(36)                                              NOT NULL,
  restaurant_id  CHAR(36)                                              NOT NULL,
  payment_method ENUM('cash','card')                                   NOT NULL,
  status         ENUM('pending','preparing','ready','completed','cancelled') NOT NULL DEFAULT 'pending',
  pickup_code    CHAR(3)                                               NOT NULL,
  created_at     DATETIME(3)                                           NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_orders_seq (seq),
  KEY idx_orders_customer (customer_id),
  KEY idx_orders_restaurant (restaurant_id),
  CONSTRAINT fk_orders_customer   FOREIGN KEY (customer_id)   REFERENCES profiles(id),
  CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id)
) ENGINE=InnoDB AUTO_INCREMENT=2048;

-- ---------------------------------------------------------------------
-- 11. order_lines — renglones de cada pedido (nombre/precio congelados)
-- ---------------------------------------------------------------------
CREATE TABLE order_lines (
  id           CHAR(36)      NOT NULL,
  order_id     CHAR(36)      NOT NULL,
  product_id   CHAR(36)      NULL,
  product_name VARCHAR(150)  NOT NULL,
  quantity     INT           NOT NULL,
  unit_price   DECIMAL(10,2) NOT NULL,
  notes        VARCHAR(300)  NULL,
  PRIMARY KEY (id),
  KEY idx_lines_order (order_id),
  CONSTRAINT fk_lines_order   FOREIGN KEY (order_id)   REFERENCES orders(id)   ON DELETE CASCADE,
  CONSTRAINT fk_lines_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
  CONSTRAINT chk_lines_quantity CHECK (quantity >= 1),
  CONSTRAINT chk_lines_price    CHECK (unit_price >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 12. notifications — avisos por usuario (creados solo por el sistema)
-- ---------------------------------------------------------------------
CREATE TABLE notifications (
  id             CHAR(36)     NOT NULL,
  recipient_id   CHAR(36)     NOT NULL,
  order_id       CHAR(36)     NOT NULL,
  related_status ENUM('pending','preparing','ready','completed','cancelled') NULL,
  title          VARCHAR(150) NOT NULL,
  message        VARCHAR(300) NOT NULL,
  is_read        TINYINT(1)   NOT NULL DEFAULT 0,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_notifications_recipient (recipient_id),
  CONSTRAINT fk_notifications_recipient FOREIGN KEY (recipient_id) REFERENCES profiles(id) ON DELETE CASCADE,
  CONSTRAINT fk_notifications_order     FOREIGN KEY (order_id)     REFERENCES orders(id)   ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- Seed de catálogos fijos
-- =====================================================================

INSERT INTO restaurant_categories (name) VALUES
  ('Mexicana'),
  ('Saludable'),
  ('Cafetería'),
  ('Antojitos'),
  ('Internacional'),
  ('Postres');

-- IMPORTANTE: estos nombres deben coincidir con el enum ProductCategory
-- de la app SwiftUI (rawValue), o la decodificación fallará.
INSERT INTO product_categories (name, sort_order) VALUES
  ('Lo más pedido', 0),
  ('Platillos',     1),
  ('Antojitos',     2),
  ('Bebidas',       3),
  ('Postres',       4);

INSERT INTO tags (name) VALUES
  ('Sin filas'),
  ('Popular'),
  ('Nuevo'),
  ('Saludable'),
  ('Económico');
