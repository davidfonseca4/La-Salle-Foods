package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.config.SupabaseConfig;
import mx.lasalle.lasallefoods.http.ProxyResponse;
import mx.lasalle.lasallefoods.http.SupabaseGateway;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Fachada de restaurantes: /api/restaurants y /api/restaurants/*.
 *
 * - GET    /api/restaurants                  -> lista (is_active=eq.true)
 * - GET    /api/restaurants/{id}             -> detalle + productos
 * - GET    /api/restaurants/{id}/products    -> productos del restaurante
 * - POST   /api/restaurants                  -> alta (dueno)
 * - PATCH  /api/restaurants/{id}             -> edicion (dueno)
 * - PUT    /api/restaurants/{id}/tags        -> reemplaza set de tags
 *
 * Mapeo declarado en web.xml.
 */
public class RestaurantServlet extends HttpServlet {

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
                case "GET" -> handleGet(req, resp, segments, auth);
                case "POST" -> handlePost(req, resp, segments, auth);
                case "PATCH" -> handlePatch(req, resp, segments, auth);
                case "PUT" -> handlePut(req, resp, segments, auth);
                default -> resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Upstream interrupted");
        }
    }

    private void handleGet(HttpServletRequest req, HttpServletResponse resp, String[] segments, String auth)
            throws IOException, InterruptedException {
        ProxyResponse upstream;
        if (segments.length == 0 || segments[0].isEmpty()) {
            upstream = gateway.forward("GET", "/rest/v1/restaurants",
                    "select=*,restaurant_categories(name),restaurant_tags(tags(name))",
                    auth, null, null);
        } else if (segments.length == 1) {
            String id = segments[0];
            upstream = gateway.forward("GET", "/rest/v1/restaurants",
                    "id=eq." + id + "&select=*,products(*)", auth, null, null);
        } else if (segments.length == 2 && "products".equals(segments[1])) {
            String id = segments[0];
            upstream = gateway.forward("GET", "/rest/v1/products",
                    "restaurant_id=eq." + id + "&select=*,product_categories(name)", auth, null, null);
        } else {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        writeProxyResponse(resp, upstream);
    }

    private void handlePost(HttpServletRequest req, HttpServletResponse resp, String[] segments, String auth)
            throws IOException, InterruptedException {
        if (segments.length != 0 && !segments[0].isEmpty()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        byte[] body = req.getInputStream().readAllBytes();
        ProxyResponse upstream = gateway.forward("POST", "/rest/v1/restaurants", null, auth, body, req.getContentType());
        writeProxyResponse(resp, upstream);
    }

    private void handlePatch(HttpServletRequest req, HttpServletResponse resp, String[] segments, String auth)
            throws IOException, InterruptedException {
        if (segments.length != 1 || segments[0].isEmpty()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        String id = segments[0];
        byte[] body = req.getInputStream().readAllBytes();
        ProxyResponse upstream = gateway.forward("PATCH", "/rest/v1/restaurants",
                "id=eq." + id, auth, body, req.getContentType());
        writeProxyResponse(resp, upstream);
    }

    private void handlePut(HttpServletRequest req, HttpServletResponse resp, String[] segments, String auth)
            throws IOException, InterruptedException {
        if (segments.length != 2 || !"tags".equals(segments[1])) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        String restaurantId = segments[0];
        byte[] body = req.getInputStream().readAllBytes();

        JSONArray tagIds;
        try {
            JSONObject json = new JSONObject(new String(body, StandardCharsets.UTF_8));
            tagIds = json.getJSONArray("tag_ids");
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Body invalido: se espera {\"tag_ids\": [..]}");
            return;
        }

        // Reemplazar el set completo: primero borrar las relaciones actuales.
        ProxyResponse deleteResp = gateway.forward("DELETE", "/rest/v1/restaurant_tags",
                "restaurant_id=eq." + restaurantId, auth, null, null);
        if (deleteResp.status() >= 300) {
            writeProxyResponse(resp, deleteResp);
            return;
        }

        if (tagIds.isEmpty()) {
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
            return;
        }

        JSONArray rows = new JSONArray();
        for (int i = 0; i < tagIds.length(); i++) {
            JSONObject row = new JSONObject();
            row.put("restaurant_id", restaurantId);
            row.put("tag_id", tagIds.getInt(i));
            rows.put(row);
        }

        ProxyResponse insertResp = gateway.forward("POST", "/rest/v1/restaurant_tags", null, auth,
                rows.toString().getBytes(StandardCharsets.UTF_8), "application/json");
        writeProxyResponse(resp, insertResp);
    }

    private void writeProxyResponse(HttpServletResponse resp, ProxyResponse upstream) throws IOException {
        resp.setStatus(upstream.status());
        resp.setContentType("application/json");
        resp.getOutputStream().write(upstream.body());
    }
}
