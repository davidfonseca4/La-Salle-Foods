package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.repo.CatalogRepository;
import mx.lasalle.lasallefoods.web.ApiException;
import mx.lasalle.lasallefoods.web.ApiServlet;
import mx.lasalle.lasallefoods.web.Responses;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Catálogos públicos de solo lectura:
 * - GET /api/restaurant-categories
 * - GET /api/product-categories
 * - GET /api/tags
 */
public class CatalogServlet extends ApiServlet {

    private final CatalogRepository repo = new CatalogRepository();

    @Override
    protected void handle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        if (!"GET".equals(req.getMethod())) {
            methodNotAllowed();
        }
        switch (req.getServletPath()) {
            case "/api/restaurant-categories" -> Responses.ok(resp, repo.restaurantCategories());
            case "/api/product-categories" -> Responses.ok(resp, repo.productCategories());
            case "/api/tags" -> Responses.ok(resp, repo.tags());
            default -> throw ApiException.notFound("Catálogo no encontrado.");
        }
    }
}
