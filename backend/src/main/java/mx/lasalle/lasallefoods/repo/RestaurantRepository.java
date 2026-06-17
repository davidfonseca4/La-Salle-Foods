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

/** Acceso a restaurantes, con embeds de categoría y etiquetas. */
public final class RestaurantRepository {

    private static final String SELECT =
            "SELECT r.id, r.owner_id, r.category_id, r.name, r.description, r.location, r.symbol, "
                    + "r.cover_color, r.rating, r.review_count, r.prep_time_min, r.prep_time_max, "
                    + "r.is_open, r.is_active, rc.name AS category_name "
                    + "FROM restaurants r JOIN restaurant_categories rc ON rc.id = r.category_id ";

    /** Lista visible: locales activos, más el propio del dueño aunque esté inactivo. */
    public JSONArray listVisible(String viewerId) throws SQLException {
        String sql = SELECT + "WHERE r.is_active = 1 OR r.owner_id = ? ORDER BY r.name";
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, viewerId);
            return toArray(conn, ps);
        }
    }

    /** Restaurantes de un dueño (usado por la app para resolver su local). */
    public JSONArray byOwner(String ownerId) throws SQLException {
        String sql = SELECT + "WHERE r.owner_id = ? ORDER BY r.name";
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, ownerId);
            return toArray(conn, ps);
        }
    }

    /** Detalle de un restaurante por id (visible según reglas). */
    public JSONArray byId(String viewerId, String id) throws SQLException {
        String sql = SELECT + "WHERE r.id = ? AND (r.is_active = 1 OR r.owner_id = ?)";
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.setString(2, viewerId);
            return toArray(conn, ps);
        }
    }

    /** Alta de local: solo dueño, registrándose a sí mismo (uno por dueño). */
    public JSONObject create(String ownerId, JSONObject body) throws SQLException, ApiException {
        String id = Ids.uuid();
        try (Connection conn = Db.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO restaurants (id, owner_id, category_id, name, description, location, "
                            + "symbol, cover_color, prep_time_min, prep_time_max) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
                ps.setString(1, id);
                ps.setString(2, ownerId); // se ignora owner_id del body: siempre el autenticado
                ps.setInt(3, body.getInt("category_id"));
                ps.setString(4, body.getString("name"));
                ps.setString(5, body.optString("description", "Nuevo local en el campus."));
                ps.setString(6, body.optString("location", ""));
                ps.setString(7, body.optString("symbol", "storefront.fill"));
                ps.setString(8, normalizeColor(body.optString("cover_color", "#FF7426")));
                ps.setInt(9, body.optInt("prep_time_min", 8));
                ps.setInt(10, body.optInt("prep_time_max", 15));
                ps.executeUpdate();
            } catch (SQLException e) {
                if (e.getMessage() != null && e.getMessage().contains("Duplicate entry")) {
                    throw ApiException.conflict("Cada dueño solo puede tener un local.");
                }
                throw e;
            }
            JSONArray created = byId(ownerId, id, conn);
            return created.isEmpty() ? new JSONObject().put("id", id) : created.getJSONObject(0);
        }
    }

    /** Edición de los datos del propio local. */
    public JSONObject update(String ownerId, String id, JSONObject body)
            throws SQLException, ApiException {
        try (Connection conn = Db.getConnection()) {
            requireOwner(conn, ownerId, id);

            StringBuilder sql = new StringBuilder("UPDATE restaurants SET ");
            JSONArray values = new JSONArray();
            boolean first = true;
            if (body.has("name"))         { sql.append(sep(first)).append("name = ?");          values.put(body.getString("name")); first = false; }
            if (body.has("description"))  { sql.append(sep(first)).append("description = ?");   values.put(body.optString("description", "")); first = false; }
            if (body.has("location"))     { sql.append(sep(first)).append("location = ?");      values.put(body.optString("location", "")); first = false; }
            if (body.has("symbol"))       { sql.append(sep(first)).append("symbol = ?");        values.put(body.getString("symbol")); first = false; }
            if (body.has("cover_color"))  { sql.append(sep(first)).append("cover_color = ?");   values.put(normalizeColor(body.getString("cover_color"))); first = false; }
            if (body.has("category_id"))  { sql.append(sep(first)).append("category_id = ?");   values.put(body.getInt("category_id")); first = false; }
            if (body.has("prep_time_min")){ sql.append(sep(first)).append("prep_time_min = ?"); values.put(body.getInt("prep_time_min")); first = false; }
            if (body.has("prep_time_max")){ sql.append(sep(first)).append("prep_time_max = ?"); values.put(body.getInt("prep_time_max")); first = false; }
            if (body.has("is_open"))      { sql.append(sep(first)).append("is_open = ?");       values.put(body.getBoolean("is_open")); first = false; }
            if (body.has("is_active"))    { sql.append(sep(first)).append("is_active = ?");     values.put(body.getBoolean("is_active")); first = false; }

            if (!first) {
                sql.append(" WHERE id = ?");
                try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                    int i = 1;
                    for (int v = 0; v < values.length(); v++) {
                        Object value = values.get(v);
                        if (value instanceof Integer integer) {
                            ps.setInt(i++, integer);
                        } else if (value instanceof Boolean b) {
                            ps.setBoolean(i++, b);
                        } else {
                            ps.setString(i++, value.toString());
                        }
                    }
                    ps.setString(i, id);
                    ps.executeUpdate();
                }
            }
            JSONArray updated = byId(ownerId, id, conn);
            return updated.isEmpty() ? new JSONObject().put("id", id) : updated.getJSONObject(0);
        }
    }

    /** Reemplaza el conjunto de etiquetas del local. */
    public void replaceTags(String ownerId, String id, JSONArray tagIds)
            throws SQLException, ApiException {
        try (Connection conn = Db.getConnection()) {
            requireOwner(conn, ownerId, id);
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement del = conn.prepareStatement(
                        "DELETE FROM restaurant_tags WHERE restaurant_id = ?")) {
                    del.setString(1, id);
                    del.executeUpdate();
                }
                if (tagIds != null && !tagIds.isEmpty()) {
                    try (PreparedStatement ins = conn.prepareStatement(
                            "INSERT INTO restaurant_tags (restaurant_id, tag_id) VALUES (?, ?)")) {
                        for (int i = 0; i < tagIds.length(); i++) {
                            ins.setString(1, id);
                            ins.setInt(2, tagIds.getInt(i));
                            ins.addBatch();
                        }
                        ins.executeBatch();
                    }
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    // --- Privado ---

    private void requireOwner(Connection conn, String ownerId, String id)
            throws SQLException, ApiException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM restaurants WHERE id = ? AND owner_id = ?")) {
            ps.setString(1, id);
            ps.setString(2, ownerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw ApiException.forbidden("Solo puedes modificar tu propio local.");
                }
            }
        }
    }

    private JSONArray byId(String viewerId, String id, Connection conn) throws SQLException {
        String sql = SELECT + "WHERE r.id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            return toArray(conn, ps);
        }
    }

    private JSONArray toArray(Connection conn, PreparedStatement ps) throws SQLException {
        try (ResultSet rs = ps.executeQuery()) {
            JSONArray array = new JSONArray();
            while (rs.next()) {
                array.put(toJson(conn, rs));
            }
            return array;
        }
    }

    private JSONObject toJson(Connection conn, ResultSet rs) throws SQLException {
        String id = rs.getString("id");
        return new JSONObject()
                .put("id", id)
                .put("owner_id", rs.getString("owner_id"))
                .put("category_id", rs.getInt("category_id"))
                .put("name", rs.getString("name"))
                .put("description", rs.getString("description"))
                .put("location", rs.getString("location"))
                .put("symbol", rs.getString("symbol"))
                .put("cover_color", rs.getString("cover_color"))
                .put("rating", rs.getDouble("rating"))
                .put("review_count", rs.getInt("review_count"))
                .put("prep_time_min", rs.getInt("prep_time_min"))
                .put("prep_time_max", rs.getInt("prep_time_max"))
                .put("is_open", rs.getBoolean("is_open"))
                .put("is_active", rs.getBoolean("is_active"))
                .put("restaurant_categories", new JSONObject().put("name", rs.getString("category_name")))
                .put("restaurant_tags", loadTags(conn, id));
    }

    private JSONArray loadTags(Connection conn, String restaurantId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT t.name FROM restaurant_tags rt JOIN tags t ON t.id = rt.tag_id "
                        + "WHERE rt.restaurant_id = ? ORDER BY t.name")) {
            ps.setString(1, restaurantId);
            try (ResultSet rs = ps.executeQuery()) {
                JSONArray array = new JSONArray();
                while (rs.next()) {
                    array.put(new JSONObject().put("tags",
                            new JSONObject().put("name", rs.getString("name"))));
                }
                return array;
            }
        }
    }

    private static String sep(boolean first) {
        return first ? "" : ", ";
    }

    private static String normalizeColor(String color) {
        if (color == null || color.isBlank()) {
            return "#FF7426";
        }
        String c = color.trim();
        if (!c.startsWith("#")) {
            c = "#" + c;
        }
        return c.matches("^#[0-9A-Fa-f]{6}$") ? c : "#FF7426";
    }
}
