package mx.lasalle.lasallefoods.repo;

import mx.lasalle.lasallefoods.db.Db;
import mx.lasalle.lasallefoods.util.Ids;
import mx.lasalle.lasallefoods.web.ApiException;
import org.json.JSONArray;
import org.json.JSONObject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/** Acceso a productos, con la lógica de autorización del dueño. */
public final class ProductRepository {

    private static final String SELECT =
            "SELECT p.id, p.restaurant_id, p.category_id, p.name, p.description, p.price, "
                    + "p.symbol, p.is_available, p.is_popular, pc.name AS category_name "
                    + "FROM products p JOIN product_categories pc ON pc.id = p.category_id ";

    /** Productos visibles: de locales activos o del propio local del dueño. */
    public JSONArray listVisible(String viewerId) throws SQLException {
        String sql = SELECT
                + "JOIN restaurants r ON r.id = p.restaurant_id "
                + "WHERE r.is_active = 1 OR r.owner_id = ? "
                + "ORDER BY p.name";
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, viewerId); // null => solo activos
            return toArray(ps);
        }
    }

    public JSONArray byRestaurant(String restaurantId) throws SQLException {
        String sql = SELECT + "WHERE p.restaurant_id = ? ORDER BY p.name";
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, restaurantId);
            return toArray(ps);
        }
    }

    /** Alta de producto: solo el dueño del local indicado. */
    public JSONObject create(String ownerId, JSONObject body) throws SQLException, ApiException {
        String restaurantId = body.optString("restaurant_id", null);
        if (restaurantId == null) {
            throw ApiException.badRequest("Falta el restaurante.");
        }
        try (Connection conn = Db.getConnection()) {
            requireOwnedRestaurant(conn, ownerId, restaurantId);
            String id = Ids.uuid();
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO products (id, restaurant_id, category_id, name, description, "
                            + "price, symbol, is_available, is_popular) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
                ps.setString(1, id);
                ps.setString(2, restaurantId);
                ps.setInt(3, body.getInt("category_id"));
                ps.setString(4, body.getString("name"));
                ps.setString(5, body.optString("description", ""));
                ps.setBigDecimal(6, body.getBigDecimal("price"));
                ps.setString(7, body.optString("symbol", "fork.knife"));
                ps.setBoolean(8, body.optBoolean("is_available", true));
                ps.setBoolean(9, body.optBoolean("is_popular", false));
                ps.executeUpdate();
            }
            return new JSONObject().put("id", id);
        }
    }

    /** Edición de producto: solo el dueño del local al que pertenece. */
    public void update(String ownerId, String productId, JSONObject body)
            throws SQLException, ApiException {
        try (Connection conn = Db.getConnection()) {
            requireOwnedProduct(conn, ownerId, productId);

            StringBuilder sql = new StringBuilder("UPDATE products SET ");
            JSONArray values = new JSONArray();
            boolean first = true;
            if (body.has("name"))        { sql.append(first ? "" : ", ").append("name = ?");         values.put(body.getString("name")); first = false; }
            if (body.has("description")) { sql.append(first ? "" : ", ").append("description = ?");  values.put(body.optString("description", "")); first = false; }
            if (body.has("price"))       { sql.append(first ? "" : ", ").append("price = ?");        values.put(body.getBigDecimal("price")); first = false; }
            if (body.has("category_id")) { sql.append(first ? "" : ", ").append("category_id = ?");  values.put(body.getInt("category_id")); first = false; }
            if (body.has("symbol"))      { sql.append(first ? "" : ", ").append("symbol = ?");       values.put(body.getString("symbol")); first = false; }
            if (body.has("is_available")){ sql.append(first ? "" : ", ").append("is_available = ?"); values.put(body.getBoolean("is_available")); first = false; }
            if (body.has("is_popular"))  { sql.append(first ? "" : ", ").append("is_popular = ?");   values.put(body.getBoolean("is_popular")); first = false; }

            if (first) {
                return; // nada que actualizar
            }
            sql.append(" WHERE id = ?");

            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                int i = 1;
                for (int v = 0; v < values.length(); v++) {
                    Object value = values.get(v);
                    if (value instanceof java.math.BigDecimal d) {
                        ps.setBigDecimal(i++, d);
                    } else if (value instanceof Integer integer) {
                        ps.setInt(i++, integer);
                    } else if (value instanceof Boolean b) {
                        ps.setBoolean(i++, b);
                    } else {
                        ps.setString(i++, value.toString());
                    }
                }
                ps.setString(i, productId);
                ps.executeUpdate();
            }
        }
    }

    /** Baja de producto: solo el dueño del local al que pertenece. */
    public void delete(String ownerId, String productId) throws SQLException, ApiException {
        try (Connection conn = Db.getConnection()) {
            requireOwnedProduct(conn, ownerId, productId);
            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM products WHERE id = ?")) {
                ps.setString(1, productId);
                ps.executeUpdate();
            }
        }
    }

    // --- Privado ---

    private void requireOwnedRestaurant(Connection conn, String ownerId, String restaurantId)
            throws SQLException, ApiException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM restaurants WHERE id = ? AND owner_id = ?")) {
            ps.setString(1, restaurantId);
            ps.setString(2, ownerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw ApiException.forbidden("No puedes modificar productos de otro local.");
                }
            }
        }
    }

    private void requireOwnedProduct(Connection conn, String ownerId, String productId)
            throws SQLException, ApiException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM products p JOIN restaurants r ON r.id = p.restaurant_id "
                        + "WHERE p.id = ? AND r.owner_id = ?")) {
            ps.setString(1, productId);
            ps.setString(2, ownerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw ApiException.forbidden("No puedes modificar productos de otro local.");
                }
            }
        }
    }

    private JSONArray toArray(PreparedStatement ps) throws SQLException {
        try (ResultSet rs = ps.executeQuery()) {
            JSONArray array = new JSONArray();
            while (rs.next()) {
                array.put(toJson(rs));
            }
            return array;
        }
    }

    static JSONObject toJson(ResultSet rs) throws SQLException {
        return new JSONObject()
                .put("id", rs.getString("id"))
                .put("restaurant_id", rs.getString("restaurant_id"))
                .put("category_id", rs.getInt("category_id"))
                .put("name", rs.getString("name"))
                .put("description", rs.getString("description"))
                .put("price", rs.getDouble("price"))
                .put("symbol", rs.getString("symbol"))
                .put("is_available", rs.getBoolean("is_available"))
                .put("is_popular", rs.getBoolean("is_popular"))
                .put("product_categories", new JSONObject().put("name", rs.getString("category_name")));
    }
}
