package mx.lasalle.lasallefoods.repo;

import mx.lasalle.lasallefoods.db.Db;
import mx.lasalle.lasallefoods.util.Ids;
import mx.lasalle.lasallefoods.util.TimeUtil;
import mx.lasalle.lasallefoods.web.ApiException;
import org.json.JSONArray;
import org.json.JSONObject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;

/** Acceso a pedidos y toda su lógica de negocio (folio, estados, avisos). */
public final class OrderRepository {

    private static final List<String> FLOW = List.of("pending", "preparing", "ready", "completed");

    // =====================================================================
    // Crear pedido
    // =====================================================================

    public JSONObject placeOrder(String studentId, JSONObject body) throws SQLException, ApiException {
        String restaurantId = body.optString("p_restaurant_id", null);
        String paymentMethod = body.optString("p_payment_method", null);
        JSONArray items = body.optJSONArray("p_items");

        if (restaurantId == null) {
            throw ApiException.badRequest("Falta el restaurante del pedido.");
        }
        if (!"cash".equals(paymentMethod) && !"card".equals(paymentMethod)) {
            throw ApiException.badRequest("Método de pago inválido.");
        }
        if (items == null || items.isEmpty()) {
            throw ApiException.badRequest("El pedido no tiene productos.");
        }

        try (Connection conn = Db.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // 1. Restaurante activo + dueño.
                String ownerId;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT owner_id, is_active FROM restaurants WHERE id = ?")) {
                    ps.setString(1, restaurantId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw ApiException.notFound("El local no existe.");
                        }
                        if (!rs.getBoolean("is_active")) {
                            throw ApiException.badRequest("El local no está disponible en este momento.");
                        }
                        ownerId = rs.getString("owner_id");
                    }
                }

                // 2. Insertar pedido (con código y created_at explícitos).
                String orderId = Ids.uuid();
                String pickupCode = Ids.pickupCode();
                Timestamp createdAt = Timestamp.from(Instant.now());
                long seq;
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO orders (id, customer_id, restaurant_id, payment_method, status, "
                                + "pickup_code, created_at) VALUES (?, ?, ?, ?, 'pending', ?, ?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, orderId);
                    ps.setString(2, studentId);
                    ps.setString(3, restaurantId);
                    ps.setString(4, paymentMethod);
                    ps.setString(5, pickupCode);
                    ps.setTimestamp(6, createdAt);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        seq = keys.next() ? keys.getLong(1) : 0L;
                    }
                }

                // 3. Validar e insertar renglones (precio/nombre tomados del servidor).
                try (PreparedStatement findProduct = conn.prepareStatement(
                        "SELECT name, price, is_available FROM products "
                                + "WHERE id = ? AND restaurant_id = ?");
                     PreparedStatement insertLine = conn.prepareStatement(
                             "INSERT INTO order_lines (id, order_id, product_id, product_name, "
                                     + "quantity, unit_price, notes) VALUES (?, ?, ?, ?, ?, ?, ?)")) {

                    for (int i = 0; i < items.length(); i++) {
                        JSONObject item = items.getJSONObject(i);
                        String productId = item.optString("product_id", null);
                        int quantity = item.optInt("quantity", 0);
                        String notes = item.has("notes") && !item.isNull("notes")
                                ? item.optString("notes", null) : null;

                        if (productId == null || quantity < 1) {
                            throw ApiException.badRequest("Hay un producto inválido en el pedido.");
                        }

                        findProduct.setString(1, productId);
                        findProduct.setString(2, restaurantId);
                        try (ResultSet rs = findProduct.executeQuery()) {
                            if (!rs.next()) {
                                throw ApiException.badRequest(
                                        "Un producto del pedido no pertenece a este local.");
                            }
                            if (!rs.getBoolean("is_available")) {
                                throw ApiException.badRequest(
                                        "El producto \"" + rs.getString("name") + "\" ya no está disponible.");
                            }
                            insertLine.setString(1, Ids.uuid());
                            insertLine.setString(2, orderId);
                            insertLine.setString(3, productId);
                            insertLine.setString(4, rs.getString("name"));
                            insertLine.setInt(5, quantity);
                            insertLine.setBigDecimal(6, rs.getBigDecimal("price"));
                            if (notes == null || notes.isBlank()) {
                                insertLine.setNull(7, java.sql.Types.VARCHAR);
                            } else {
                                insertLine.setString(7, notes);
                            }
                            insertLine.addBatch();
                        }
                    }
                    insertLine.executeBatch();
                }

                String folio = "LSF-" + seq;

                // 4. Notificar al dueño del local.
                NotificationRepository.insert(conn, ownerId, orderId, "pending",
                        "Nuevo pedido", "Recibiste el pedido " + folio + ".");

                conn.commit();

                return new JSONObject()
                        .put("id", orderId)
                        .put("folio", folio)
                        .put("status", "pending")
                        .put("created_at", TimeUtil.iso(createdAt))
                        .put("pickup_code", pickupCode);
            } catch (SQLException | ApiException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    // =====================================================================
    // Consultar pedidos
    // =====================================================================

    public JSONArray listForUser(String userId, String role) throws SQLException {
        boolean owner = "owner".equals(role);
        String where = owner
                ? "r.owner_id = ?"
                : "o.customer_id = ?";
        return queryOrders(where, userId, null);
    }

    public JSONArray byId(String userId, String role, String orderId) throws SQLException {
        boolean owner = "owner".equals(role);
        String where = owner
                ? "r.owner_id = ? AND o.id = ?"
                : "o.customer_id = ? AND o.id = ?";
        return queryOrders(where, userId, orderId);
    }

    private JSONArray queryOrders(String where, String userId, String orderId) throws SQLException {
        String sql = "SELECT o.id, o.seq, o.restaurant_id, o.payment_method, o.status, "
                + "o.pickup_code, o.created_at, r.name AS restaurant_name "
                + "FROM orders o JOIN restaurants r ON r.id = o.restaurant_id "
                + "WHERE " + where + " ORDER BY o.created_at DESC";
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            if (orderId != null) {
                ps.setString(2, orderId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                JSONArray array = new JSONArray();
                while (rs.next()) {
                    String id = rs.getString("id");
                    array.put(new JSONObject()
                            .put("id", id)
                            .put("folio", "LSF-" + rs.getLong("seq"))
                            .put("restaurant_id", rs.getString("restaurant_id"))
                            .put("payment_method", rs.getString("payment_method"))
                            .put("status", rs.getString("status"))
                            .put("pickup_code", rs.getString("pickup_code"))
                            .put("created_at", TimeUtil.iso(rs.getTimestamp("created_at")))
                            .put("restaurants", new JSONObject().put("name", rs.getString("restaurant_name")))
                            .put("order_lines", lines(conn, id)));
                }
                return array;
            }
        }
    }

    private JSONArray lines(Connection conn, String orderId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id, product_name, quantity, unit_price, notes "
                        + "FROM order_lines WHERE order_id = ?")) {
            ps.setString(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                JSONArray array = new JSONArray();
                while (rs.next()) {
                    String notes = rs.getString("notes");
                    array.put(new JSONObject()
                            .put("id", rs.getString("id"))
                            .put("product_name", rs.getString("product_name"))
                            .put("quantity", rs.getInt("quantity"))
                            .put("unit_price", rs.getDouble("unit_price"))
                            .put("notes", notes == null ? JSONObject.NULL : notes));
                }
                return array;
            }
        }
    }

    // =====================================================================
    // Cancelar pedido (alumno dueño del pedido o dueño del local; solo pendiente)
    // =====================================================================

    public JSONObject cancel(String userId, String role, String orderId)
            throws SQLException, ApiException {
        try (Connection conn = Db.getConnection()) {
            conn.setAutoCommit(false);
            try {
                String customerId;
                String ownerId;
                String status;
                String folio;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT o.customer_id, o.status, o.seq, r.owner_id "
                                + "FROM orders o JOIN restaurants r ON r.id = o.restaurant_id "
                                + "WHERE o.id = ?")) {
                    ps.setString(1, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw ApiException.notFound("El pedido no existe.");
                        }
                        customerId = rs.getString("customer_id");
                        ownerId = rs.getString("owner_id");
                        status = rs.getString("status");
                        folio = "LSF-" + rs.getLong("seq");
                    }
                }

                boolean isCustomer = userId.equals(customerId);
                boolean isOwner = userId.equals(ownerId);
                if (!isCustomer && !isOwner) {
                    throw ApiException.forbidden("No puedes cancelar este pedido.");
                }
                if (!"pending".equals(status)) {
                    throw ApiException.badRequest(
                            "Solo se puede cancelar mientras el pedido siga pendiente.");
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE orders SET status = 'cancelled' WHERE id = ?")) {
                    ps.setString(1, orderId);
                    ps.executeUpdate();
                }

                // Avisar a la contraparte.
                if (isCustomer) {
                    NotificationRepository.insert(conn, ownerId, orderId, "cancelled",
                            "Pedido cancelado", "El alumno canceló el pedido " + folio + ".");
                } else {
                    NotificationRepository.insert(conn, customerId, orderId, "cancelled",
                            "Pedido cancelado", "El local canceló tu pedido " + folio + ".");
                }

                conn.commit();
                return new JSONObject().put("id", orderId).put("status", "cancelled");
            } catch (SQLException | ApiException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    // =====================================================================
    // Avanzar estado (solo dueño; secuencia estricta sin saltos ni retrocesos)
    // =====================================================================

    public JSONObject updateStatus(String ownerId, String orderId, String newStatus)
            throws SQLException, ApiException {
        if (!FLOW.contains(newStatus)) {
            throw ApiException.badRequest("Estado de pedido inválido.");
        }
        try (Connection conn = Db.getConnection()) {
            conn.setAutoCommit(false);
            try {
                String customerId;
                String currentStatus;
                String folio;
                String pickupCode;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT o.customer_id, o.status, o.seq, o.pickup_code, r.owner_id "
                                + "FROM orders o JOIN restaurants r ON r.id = o.restaurant_id "
                                + "WHERE o.id = ?")) {
                    ps.setString(1, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw ApiException.notFound("El pedido no existe.");
                        }
                        if (!ownerId.equals(rs.getString("owner_id"))) {
                            throw ApiException.forbidden("Solo el dueño del local puede actualizar el pedido.");
                        }
                        customerId = rs.getString("customer_id");
                        currentStatus = rs.getString("status");
                        folio = "LSF-" + rs.getLong("seq");
                        pickupCode = rs.getString("pickup_code");
                    }
                }

                int currentStep = FLOW.indexOf(currentStatus);
                int newStep = FLOW.indexOf(newStatus);
                if (currentStep < 0) {
                    throw ApiException.badRequest("El pedido ya no puede cambiar de estado.");
                }
                if (newStep != currentStep + 1) {
                    throw ApiException.badRequest(
                            "El pedido debe avanzar paso a paso: pendiente → preparando → listo → completado.");
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE orders SET status = ? WHERE id = ?")) {
                    ps.setString(1, newStatus);
                    ps.setString(2, orderId);
                    ps.executeUpdate();
                }

                String[] copy = statusNotification(newStatus, folio, pickupCode);
                NotificationRepository.insert(conn, customerId, orderId, newStatus, copy[0], copy[1]);

                conn.commit();
                return new JSONObject().put("id", orderId).put("status", newStatus);
            } catch (SQLException | ApiException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private static String[] statusNotification(String status, String folio, String pickupCode) {
        return switch (status) {
            case "preparing" -> new String[]{"Tu pedido está en preparación",
                    "El local comenzó a preparar " + folio + "."};
            case "ready" -> new String[]{"Tu pedido está listo",
                    folio + " está listo para recoger. Código " + pickupCode + "."};
            case "completed" -> new String[]{"Pedido entregado",
                    "¡Disfruta tu pedido " + folio + "!"};
            default -> new String[]{"Actualización de pedido", "El estado de " + folio + " cambió."};
        };
    }
}
