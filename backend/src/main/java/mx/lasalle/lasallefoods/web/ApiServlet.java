package mx.lasalle.lasallefoods.web;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.auth.AuthContext;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;

/**
 * Base de todos los servlets de la API: envuelve el despacho con manejo
 * uniforme de errores (ApiException → JSON, SQLException → código traducido)
 * y ofrece utilidades de uso frecuente.
 */
public abstract class ApiServlet extends HttpServlet {

    /** Punto de entrada que deben implementar los servlets concretos. */
    protected abstract void handle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException;

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            handle(req, resp);
        } catch (ApiException ex) {
            Responses.error(resp, ex);
        } catch (SQLException ex) {
            Responses.error(resp, mapSql(ex));
        } catch (Exception ex) {
            Responses.error(resp, new ApiException(500, "500",
                    "Ocurrió un error inesperado en el servidor."));
        }
    }

    private static ApiException mapSql(SQLException ex) {
        String message = ex.getMessage() == null ? "" : ex.getMessage();
        if (message.contains("Duplicate entry")) {
            return ApiException.conflict("Ya existe un registro con esos datos.");
        }
        String state = ex.getSQLState();
        if (message.toLowerCase().contains("check constraint")
                || (state != null && state.startsWith("23"))) {
            return ApiException.invalidData("Datos inválidos, revisa la información ingresada.");
        }
        return new ApiException(500, "500", "Error de comunicación con la base de datos.");
    }

    // --- Utilidades ---

    /** Segmentos del path después del mapeo del servlet (sin vacíos). */
    protected static String[] segments(HttpServletRequest req) {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.isBlank() || pathInfo.equals("/")) {
            return new String[0];
        }
        String trimmed = pathInfo.replaceFirst("^/", "").replaceFirst("/$", "");
        if (trimmed.isEmpty()) {
            return new String[0];
        }
        return trimmed.split("/");
    }

    protected static JSONObject readBody(HttpServletRequest req) throws IOException, ApiException {
        byte[] raw = req.getInputStream().readAllBytes();
        if (raw.length == 0) {
            return new JSONObject();
        }
        try {
            return new JSONObject(new String(raw, StandardCharsets.UTF_8));
        } catch (JSONException e) {
            throw ApiException.badRequest("El cuerpo de la solicitud no es JSON válido.");
        }
    }

    protected static String requireAuth(HttpServletRequest req) throws ApiException {
        String userId = AuthContext.userId(req);
        if (userId == null) {
            throw ApiException.unauthorized("Tu sesión expiró. Vuelve a iniciar sesión.");
        }
        return userId;
    }

    protected static void requireOwner(HttpServletRequest req) throws ApiException {
        requireAuth(req);
        if (!AuthContext.isOwner(req)) {
            throw ApiException.forbidden("Solo un dueño puede realizar esta acción.");
        }
    }

    protected static void requireStudent(HttpServletRequest req) throws ApiException {
        requireAuth(req);
        if (!AuthContext.isStudent(req)) {
            throw ApiException.forbidden("Solo un alumno puede realizar esta acción.");
        }
    }

    protected static void methodNotAllowed() throws ApiException {
        throw new ApiException(405, "405", "Método no permitido.");
    }
}
