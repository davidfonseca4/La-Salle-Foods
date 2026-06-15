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
 * Catalogos fijos de solo lectura (RLS publica):
 * - GET /api/restaurant-categories -> /rest/v1/restaurant_categories?select=*
 * - GET /api/product-categories    -> /rest/v1/product_categories?select=*&order=sort_order
 * - GET /api/tags                  -> /rest/v1/tags?select=*
 *
 * Mapeo declarado en web.xml.
 */
public class CatalogServlet extends HttpServlet {

    private SupabaseGateway gateway;

    @Override
    public void init() throws ServletException {
        gateway = new SupabaseGateway(SupabaseConfig.url(), SupabaseConfig.anonKey());
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (!"GET".equals(req.getMethod())) {
            resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            return;
        }

        String restPath;
        String query;

        switch (req.getServletPath()) {
            case "/api/restaurant-categories" -> {
                restPath = "/rest/v1/restaurant_categories";
                query = "select=*";
            }
            case "/api/product-categories" -> {
                restPath = "/rest/v1/product_categories";
                query = "select=*&order=sort_order";
            }
            case "/api/tags" -> {
                restPath = "/rest/v1/tags";
                query = "select=*";
            }
            default -> {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
        }

        String auth = req.getHeader("Authorization");

        try {
            ProxyResponse upstream = gateway.forward("GET", restPath, query, auth, null, null);
            resp.setStatus(upstream.status());
            resp.setContentType("application/json");
            resp.getOutputStream().write(upstream.body());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Upstream interrupted");
        }
    }
}
