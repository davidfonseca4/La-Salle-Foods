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
 * Fachada de pedidos: /api/orders y /api/orders/*.
 *
 * - POST /api/orders                -> rpc place_order
 * - GET  /api/orders                -> orders + order_lines (RLS: propios del cliente o del local del dueno)
 * - GET  /api/orders/{id}           -> detalle
 * - POST /api/orders/{id}/cancel    -> rpc cancel_order
 * - POST /api/orders/{id}/status    -> rpc update_order_status
 *
 * Mapeo declarado en web.xml.
 */
public class OrderServlet extends HttpServlet {

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
                case "GET" -> handleGet(resp, segments, auth);
                case "POST" -> handlePost(req, resp, segments, auth);
                default -> resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Upstream interrupted");
        }
    }

    private void handleGet(HttpServletResponse resp, String[] segments, String auth)
            throws IOException, InterruptedException {
        ProxyResponse upstream;
        if (segments.length == 0 || segments[0].isEmpty()) {
            upstream = gateway.forward("GET", "/rest/v1/orders",
                    "select=*,restaurants(name),order_lines(*)&order=created_at.desc", auth, null, null);
        } else if (segments.length == 1) {
            upstream = gateway.forward("GET", "/rest/v1/orders",
                    "id=eq." + segments[0] + "&select=*,restaurants(name),order_lines(*)", auth, null, null);
        } else {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        writeProxyResponse(resp, upstream);
    }

    private void handlePost(HttpServletRequest req, HttpServletResponse resp, String[] segments, String auth)
            throws IOException, InterruptedException {
        ProxyResponse upstream;
        if (segments.length == 0 || segments[0].isEmpty()) {
            byte[] body = req.getInputStream().readAllBytes();
            upstream = gateway.forward("POST", "/rest/v1/rpc/place_order", null, auth, body, req.getContentType());
        } else if (segments.length == 2 && "cancel".equals(segments[1])) {
            JSONObject params = new JSONObject();
            params.put("p_order_id", segments[0]);
            upstream = gateway.forward("POST", "/rest/v1/rpc/cancel_order", null, auth,
                    params.toString().getBytes(StandardCharsets.UTF_8), "application/json");
        } else if (segments.length == 2 && "status".equals(segments[1])) {
            byte[] body = req.getInputStream().readAllBytes();
            JSONObject params = body.length == 0 ? new JSONObject() : new JSONObject(new String(body, StandardCharsets.UTF_8));
            params.put("p_order_id", segments[0]);
            upstream = gateway.forward("POST", "/rest/v1/rpc/update_order_status", null, auth,
                    params.toString().getBytes(StandardCharsets.UTF_8), "application/json");
        } else {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        writeProxyResponse(resp, upstream);
    }

    private void writeProxyResponse(HttpServletResponse resp, ProxyResponse upstream) throws IOException {
        resp.setStatus(upstream.status());
        resp.setContentType("application/json");
        resp.getOutputStream().write(upstream.body());
    }
}
