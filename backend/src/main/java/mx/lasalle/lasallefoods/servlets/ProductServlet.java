package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.config.SupabaseConfig;
import mx.lasalle.lasallefoods.http.ProxyResponse;
import mx.lasalle.lasallefoods.http.SupabaseGateway;

import java.io.IOException;

/**
 * Fachada de productos del dueno: /api/products y /api/products/*.
 *
 * - POST   /api/products       -> alta
 * - PATCH  /api/products/{id}  -> edicion (disponibilidad, precio, etc.)
 * - DELETE /api/products/{id}  -> borrado
 *
 * Mapeo declarado en web.xml.
 */
public class ProductServlet extends HttpServlet {

    private SupabaseGateway gateway;

    @Override
    public void init() throws ServletException {
        gateway = new SupabaseGateway(SupabaseConfig.url(), SupabaseConfig.anonKey());
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        String auth = req.getHeader("Authorization");

        try {
            switch (req.getMethod()) {
                case "POST" -> {
                    if (pathInfo != null && !pathInfo.equals("/")) {
                        resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                        return;
                    }
                    byte[] body = req.getInputStream().readAllBytes();
                    ProxyResponse upstream = gateway.forward("POST", "/rest/v1/products", null, auth, body, req.getContentType());
                    writeProxyResponse(resp, upstream);
                }
                case "PATCH" -> {
                    String id = idFromPath(pathInfo);
                    if (id == null) {
                        resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                        return;
                    }
                    byte[] body = req.getInputStream().readAllBytes();
                    ProxyResponse upstream = gateway.forward("PATCH", "/rest/v1/products",
                            "id=eq." + id, auth, body, req.getContentType());
                    writeProxyResponse(resp, upstream);
                }
                case "DELETE" -> {
                    String id = idFromPath(pathInfo);
                    if (id == null) {
                        resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                        return;
                    }
                    ProxyResponse upstream = gateway.forward("DELETE", "/rest/v1/products",
                            "id=eq." + id, auth, null, null);
                    writeProxyResponse(resp, upstream);
                }
                default -> resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Upstream interrupted");
        }
    }

    private static String idFromPath(String pathInfo) {
        if (pathInfo == null || pathInfo.length() < 2) {
            return null;
        }
        String stripped = pathInfo.substring(1);
        if (stripped.isEmpty() || stripped.contains("/")) {
            return null;
        }
        return stripped;
    }

    private void writeProxyResponse(HttpServletResponse resp, ProxyResponse upstream) throws IOException {
        resp.setStatus(upstream.status());
        resp.setContentType("application/json");
        resp.getOutputStream().write(upstream.body());
    }
}
