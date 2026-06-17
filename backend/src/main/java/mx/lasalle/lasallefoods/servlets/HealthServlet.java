package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.db.Db;
import org.json.JSONObject;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;

/**
 * Chequeo de vida del backend y de la conexión a MySQL: /api/health.
 */
public class HealthServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        boolean dbOk;
        try (Connection conn = Db.getConnection()) {
            dbOk = conn.isValid(2);
        } catch (Exception e) {
            dbOk = false;
        }

        JSONObject body = new JSONObject()
                .put("status", dbOk ? "ok" : "degraded")
                .put("database", dbOk ? "up" : "down");

        resp.setStatus(dbOk ? HttpServletResponse.SC_OK : HttpServletResponse.SC_SERVICE_UNAVAILABLE);
        resp.setContentType("application/json; charset=UTF-8");
        resp.getOutputStream().write(body.toString().getBytes(StandardCharsets.UTF_8));
    }
}
