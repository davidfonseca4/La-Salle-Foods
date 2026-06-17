package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.repo.NotificationRepository;
import mx.lasalle.lasallefoods.web.ApiException;
import mx.lasalle.lasallefoods.web.ApiServlet;
import mx.lasalle.lasallefoods.web.Responses;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Notificaciones: /api/notifications y /api/notifications/*.
 *
 * - GET  /api/notifications           -> avisos propios
 * - POST /api/notifications/{id}/read -> marcar como leída (solo propias)
 */
public class NotificationServlet extends ApiServlet {

    private final NotificationRepository notifications = new NotificationRepository();

    @Override
    protected void handle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        String userId = requireAuth(req);
        String[] s = segments(req);

        switch (req.getMethod()) {
            case "GET" -> {
                if (s.length != 0) {
                    throw ApiException.notFound("Recurso no encontrado.");
                }
                Responses.ok(resp, notifications.listForUser(userId));
            }
            case "POST" -> {
                if (s.length != 2 || !"read".equals(s[1])) {
                    throw ApiException.notFound("Recurso no encontrado.");
                }
                notifications.markRead(userId, s[0]);
                Responses.noContent(resp);
            }
            default -> methodNotAllowed();
        }
    }
}
