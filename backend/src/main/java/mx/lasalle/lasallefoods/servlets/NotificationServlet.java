package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.config.SupabaseConfig;
import mx.lasalle.lasallefoods.http.ProxyResponse;
import mx.lasalle.lasallefoods.http.SupabaseGateway;
import org.json.JSONObject;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Fachada de notificaciones: /api/notifications y /api/notifications/*.
 *
 * - GET  /api/notifications          -> notifications (RLS: recipient_id = auth.uid())
 * - POST /api/notifications/{id}/read -> rpc mark_notification_read
 *
 * Mapeo declarado en web.xml.
 */
public class NotificationServlet extends HttpServlet {

    private SupabaseGateway gateway;

    @Override
    public void init() throws ServletException {
        gateway = new SupabaseGateway(SupabaseConfig.url(), SupabaseConfig.anonKey());
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        String[] segments = (pathInfo == null) ? new String[0] : pathInfo.replaceFirst("^/", "").split("/");
        String auth = req.getHeader("Authorization");

        try {
            switch (req.getMethod()) {
                case "GET" -> {
                    if (segments.length != 0 && !segments[0].isEmpty()) {
                        resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                        return;
                    }
                    ProxyResponse upstream = gateway.forward("GET", "/rest/v1/notifications",
                            "select=*&order=created_at.desc", auth, null, null);
                    writeProxyResponse(resp, upstream);
                }
                case "POST" -> {
                    if (segments.length != 2 || !"read".equals(segments[1])) {
                        resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                        return;
                    }
                    JSONObject params = new JSONObject();
                    params.put("p_notification_id", segments[0]);
                    ProxyResponse upstream = gateway.forward("POST", "/rest/v1/rpc/mark_notification_read", null, auth,
                            params.toString().getBytes(StandardCharsets.UTF_8), "application/json");
                    writeProxyResponse(resp, upstream);
                }
                default -> resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Upstream interrupted");
        }
    }

    private void writeProxyResponse(HttpServletResponse resp, ProxyResponse upstream) throws IOException {
        resp.setStatus(upstream.status());
        resp.setContentType("application/json");
        resp.getOutputStream().write(upstream.body());
    }
}
