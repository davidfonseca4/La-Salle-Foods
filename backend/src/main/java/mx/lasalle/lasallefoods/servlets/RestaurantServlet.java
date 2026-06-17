package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.auth.AuthContext;
import mx.lasalle.lasallefoods.repo.ProductRepository;
import mx.lasalle.lasallefoods.repo.RestaurantRepository;
import mx.lasalle.lasallefoods.web.ApiException;
import mx.lasalle.lasallefoods.web.ApiServlet;
import mx.lasalle.lasallefoods.web.Responses;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Restaurantes: /api/restaurants y /api/restaurants/*.
 *
 * - GET    /api/restaurants               -> lista visible
 * - GET    /api/restaurants/{id}          -> detalle
 * - GET    /api/restaurants/{id}/products -> productos del local
 * - POST   /api/restaurants               -> alta (dueño)
 * - PATCH  /api/restaurants/{id}          -> edición (dueño)
 * - PUT    /api/restaurants/{id}/tags     -> reemplaza etiquetas (dueño)
 */
public class RestaurantServlet extends ApiServlet {

    private final RestaurantRepository restaurants = new RestaurantRepository();
    private final ProductRepository products = new ProductRepository();

    @Override
    protected void handle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        String[] s = segments(req);
        switch (req.getMethod()) {
            case "GET" -> get(req, resp, s);
            case "POST" -> post(req, resp, s);
            case "PATCH" -> patch(req, resp, s);
            case "PUT" -> put(req, resp, s);
            default -> methodNotAllowed();
        }
    }

    private void get(HttpServletRequest req, HttpServletResponse resp, String[] s)
            throws IOException, SQLException, ApiException {
        String viewerId = AuthContext.userId(req);
        if (s.length == 0) {
            Responses.ok(resp, restaurants.listVisible(viewerId));
        } else if (s.length == 1) {
            Responses.ok(resp, restaurants.byId(viewerId, s[0]));
        } else if (s.length == 2 && "products".equals(s[1])) {
            Responses.ok(resp, products.byRestaurant(s[0]));
        } else {
            throw ApiException.notFound("Recurso no encontrado.");
        }
    }

    private void post(HttpServletRequest req, HttpServletResponse resp, String[] s)
            throws IOException, SQLException, ApiException {
        if (s.length != 0) {
            throw ApiException.notFound("Recurso no encontrado.");
        }
        requireOwner(req);
        JSONObject created = restaurants.create(AuthContext.userId(req), readBody(req));
        Responses.created(resp, created);
    }

    private void patch(HttpServletRequest req, HttpServletResponse resp, String[] s)
            throws IOException, SQLException, ApiException {
        if (s.length != 1) {
            throw ApiException.notFound("Recurso no encontrado.");
        }
        requireOwner(req);
        JSONObject updated = restaurants.update(AuthContext.userId(req), s[0], readBody(req));
        Responses.ok(resp, updated);
    }

    private void put(HttpServletRequest req, HttpServletResponse resp, String[] s)
            throws IOException, SQLException, ApiException {
        if (s.length != 2 || !"tags".equals(s[1])) {
            throw ApiException.notFound("Recurso no encontrado.");
        }
        requireOwner(req);
        JSONObject body = readBody(req);
        JSONArray tagIds = body.optJSONArray("tag_ids");
        if (tagIds == null) {
            throw ApiException.badRequest("Se espera {\"tag_ids\": [..]}.");
        }
        restaurants.replaceTags(AuthContext.userId(req), s[0], tagIds);
        Responses.noContent(resp);
    }
}
