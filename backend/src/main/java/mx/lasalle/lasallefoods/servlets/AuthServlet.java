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
 * Autenticación propia contra MySQL: /api/auth/*.
 *
 * - POST /api/auth/register -> alta de cuenta (correo institucional) + sesión
 * - POST /api/auth/login    -> inicio de sesión
 * - POST /api/auth/refresh  -> renovación de sesión
 * - GET  /api/auth/me       -> usuario autenticado {id, email}
 * - POST /api/auth/logout   -> cierre de sesión
 */
public class AuthServlet extends ApiServlet {

    private final AuthRepository repo = new AuthRepository();

    @Override
    protected void handle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        String[] segments = segments(req);
        if (segments.length != 1) {
            throw ApiException.notFound("Ruta de autenticación no encontrada.");
        }

        switch (segments[0]) {
            case "register" -> register(req, resp);
            case "login" -> login(req, resp);
            case "refresh" -> refresh(req, resp);
            case "me" -> me(req, resp);
            case "logout" -> logout(req, resp);
            default -> throw ApiException.notFound("Ruta de autenticación no encontrada.");
        }
    }

    private void register(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        JSONObject body = readBody(req);
        JSONObject data = body.optJSONObject("data");
        String fullName = data != null ? data.optString("full_name", "") : "";
        String role = data != null ? data.optString("role", "student") : "student";
        JSONObject session = repo.register(
                body.optString("email", ""), body.optString("password", ""), fullName, role);
        Responses.json(resp, 200, session);
    }

    private void login(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        JSONObject body = readBody(req);
        JSONObject session = repo.login(body.optString("email", ""), body.optString("password", ""));
        Responses.ok(resp, session);
    }

    private void refresh(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        JSONObject body = readBody(req);
        JSONObject session = repo.refresh(body.optString("refresh_token", null));
        Responses.ok(resp, session);
    }

    private void me(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        String userId = requireAuth(req);
        Responses.ok(resp, repo.me(userId));
    }

    private void logout(HttpServletRequest req, HttpServletResponse resp) throws SQLException {
        // Idempotente: aunque el token ya no sea válido, respondemos OK.
        Object userId = req.getAttribute(mx.lasalle.lasallefoods.auth.AuthContext.ATTR_USER_ID);
        if (userId != null) {
            repo.logout(userId.toString());
        }
        Responses.noContent(resp);
    }
}
