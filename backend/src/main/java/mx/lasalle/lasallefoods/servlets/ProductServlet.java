package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.auth.AuthContext;
import mx.lasalle.lasallefoods.repo.ProductRepository;
import mx.lasalle.lasallefoods.web.ApiException;
import mx.lasalle.lasallefoods.web.ApiServlet;
import mx.lasalle.lasallefoods.web.Responses;
import org.json.JSONObject;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Productos del dueño: /api/products y /api/products/*.
 *
 * - POST   /api/products       -> alta
 * - PATCH  /api/products/{id}  -> edición
 * - DELETE /api/products/{id}  -> baja
 */
public class ProductServlet extends ApiServlet {

    private final ProductRepository products = new ProductRepository();

    @Override
    protected void handle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        String[] s = segments(req);
        requireOwner(req);
        String ownerId = AuthContext.userId(req);

        switch (req.getMethod()) {
            case "POST" -> {
                if (s.length != 0) {
                    throw ApiException.notFound("Recurso no encontrado.");
                }
                JSONObject created = products.create(ownerId, readBody(req));
                Responses.created(resp, created);
            }
            case "PATCH" -> {
                if (s.length != 1) {
                    throw ApiException.notFound("Recurso no encontrado.");
                }
                products.update(ownerId, s[0], readBody(req));
                Responses.noContent(resp);
            }
            case "DELETE" -> {
                if (s.length != 1) {
                    throw ApiException.notFound("Recurso no encontrado.");
                }
                products.delete(ownerId, s[0]);
                Responses.noContent(resp);
            }
            default -> methodNotAllowed();
        }
    }
}
