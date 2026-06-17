package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.auth.AuthContext;
import mx.lasalle.lasallefoods.repo.ProductRepository;
import mx.lasalle.lasallefoods.repo.RestaurantRepository;
import mx.lasalle.lasallefoods.web.ApiException;
import mx.lasalle.lasallefoods.web.ApiServlet;
import mx.lasalle.lasallefoods.web.Responses;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Rutas genéricas /api/db/* que usa la app SwiftUI. Solo se soportan los
 * casos reales:
 *
 * - GET /api/db/restaurants?owner_id=eq.{uuid}  -> locales del dueño
 * - GET /api/db/restaurants                     -> locales visibles
 * - GET /api/db/products                        -> productos visibles
 *
 * El parámetro `select` se ignora: el JSON ya viene con los embeds que la
 * app espera.
 */
public class DbServlet extends ApiServlet {

    private final RestaurantRepository restaurants = new RestaurantRepository();
    private final ProductRepository products = new ProductRepository();

    @Override
    protected void handle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        if (!"GET".equals(req.getMethod())) {
            methodNotAllowed();
        }
        String[] s = segments(req);
        if (s.length != 1) {
            throw ApiException.notFound("Recurso no encontrado.");
        }
        String viewerId = AuthContext.userId(req);

        switch (s[0]) {
            case "restaurants" -> {
                String ownerFilter = stripEq(req.getParameter("owner_id"));
                if (ownerFilter != null) {
                    Responses.ok(resp, restaurants.byOwner(ownerFilter));
                } else {
                    Responses.ok(resp, restaurants.listVisible(viewerId));
                }
            }
            case "products" -> Responses.ok(resp, products.listVisible(viewerId));
            default -> throw ApiException.notFound("Recurso no encontrado.");
        }
    }

    /** Convierte el filtro "eq.valor" en "valor". */
    private static String stripEq(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.startsWith("eq.") ? value.substring(3) : value;
    }
}
