package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.repo.AuthRepository;
import mx.lasalle.lasallefoods.web.ApiException;
import mx.lasalle.lasallefoods.web.ApiServlet;
import mx.lasalle.lasallefoods.web.Responses;
import org.json.JSONObject;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Perfil propio: /api/profile.
 *
 * - GET   -> [{ id, full_name, role, email }]  (solo el propio)
 * - PATCH -> actualiza full_name (el rol es inmutable)
 */
public class ProfileServlet extends ApiServlet {

    private final AuthRepository repo = new AuthRepository();

    @Override
    protected void handle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        String userId = requireAuth(req);

        switch (req.getMethod()) {
            case "GET" -> Responses.ok(resp, repo.profile(userId));
            case "PATCH" -> {
                JSONObject body = readBody(req);
                repo.updateFullName(userId, body.optString("full_name", null));
                Responses.noContent(resp);
            }
            default -> methodNotAllowed();
        }
    }
}
