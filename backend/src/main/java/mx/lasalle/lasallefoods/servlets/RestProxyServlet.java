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
 * Proxy generico de datos: /api/db/* -> {SUPABASE_URL}/rest/v1/*.
 *
 * Cubre tablas (restaurants, products, profiles, orders, notifications, ...)
 * y funciones RPC (rpc/place_order, rpc/cancel_order,
 * rpc/update_order_status, rpc/mark_notification_read). No reimplementa
 * logica de negocio: solo reenvia metodo, path, query string, body y el
 * header Authorization del cliente; agrega apikey desde configuracion del
 * servidor y devuelve status + body de Supabase tal cual.
 *
 * Mapeo declarado en web.xml.
 */
public class RestProxyServlet extends HttpServlet {

    private SupabaseGateway gateway;

    @Override
    public void init() throws ServletException {
        gateway = new SupabaseGateway(SupabaseConfig.url(), SupabaseConfig.anonKey());
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String subPath = req.getPathInfo();
        String restPath = "/rest/v1" + (subPath != null ? subPath : "");
        String auth = req.getHeader("Authorization");
        byte[] body = req.getInputStream().readAllBytes();

        try {
            ProxyResponse upstream = gateway.forward(
                    req.getMethod(), restPath, req.getQueryString(), auth, body, req.getContentType());

            resp.setStatus(upstream.status());
            resp.setContentType("application/json");
            resp.getOutputStream().write(upstream.body());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Upstream interrupted");
        }
    }
}
