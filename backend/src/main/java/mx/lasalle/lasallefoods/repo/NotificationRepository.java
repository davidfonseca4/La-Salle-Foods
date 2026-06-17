package mx.lasalle.lasallefoods.repo;

import mx.lasalle.lasallefoods.db.Db;
import mx.lasalle.lasallefoods.util.Ids;
import mx.lasalle.lasallefoods.util.TimeUtil;
import org.json.JSONArray;
import org.json.JSONObject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/** Avisos por usuario. Solo el sistema los crea (nunca el cliente). */
public final class NotificationRepository {

    public JSONArray listForUser(String userId) throws SQLException {
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT id, recipient_id, order_id, related_status, title, message, "
                             + "is_read, created_at FROM notifications "
                             + "WHERE recipient_id = ? ORDER BY created_at DESC")) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                JSONArray array = new JSONArray();
                while (rs.next()) {
                    String related = rs.getString("related_status");
                    array.put(new JSONObject()
                            .put("id", rs.getString("id"))
                            .put("recipient_id", rs.getString("recipient_id"))
                            .put("order_id", rs.getString("order_id"))
                            .put("related_status", related == null ? JSONObject.NULL : related)
                            .put("title", rs.getString("title"))
                            .put("message", rs.getString("message"))
                            .put("is_read", rs.getBoolean("is_read"))
                            .put("created_at", TimeUtil.iso(rs.getTimestamp("created_at"))));
                }
                return array;
            }
        }
    }

    /** Marca como leída una notificación propia (no puede tocar las de otros). */
    public void markRead(String userId, String notificationId) throws SQLException {
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE notifications SET is_read = 1 WHERE id = ? AND recipient_id = ?")) {
            ps.setString(1, notificationId);
            ps.setString(2, userId);
            ps.executeUpdate();
        }
    }

    /** Inserta un aviso dentro de una transacción existente (uso interno). */
    static void insert(Connection conn, String recipientId, String orderId,
                       String relatedStatus, String title, String message) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO notifications (id, recipient_id, order_id, related_status, title, message) "
                        + "VALUES (?, ?, ?, ?, ?, ?)")) {
            ps.setString(1, Ids.uuid());
            ps.setString(2, recipientId);
            ps.setString(3, orderId);
            if (relatedStatus == null) {
                ps.setNull(4, java.sql.Types.VARCHAR);
            } else {
                ps.setString(4, relatedStatus);
            }
            ps.setString(5, title);
            ps.setString(6, message);
            ps.executeUpdate();
        }
    }
}
