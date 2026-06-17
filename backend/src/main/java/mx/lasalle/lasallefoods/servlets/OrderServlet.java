package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.auth.AuthContext;
import mx.lasalle.lasallefoods.repo.OrderRepository;
import mx.lasalle.lasallefoods.web.ApiException;
import mx.lasalle.lasallefoods.web.ApiServlet;
import mx.lasalle.lasallefoods.web.Responses;
import org.json.JSONObject;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Pedidos: /api/orders y /api/orders/*.
 *
 * - GET  /api/orders             -> pedidos visibles (alumno: propios; dueño: del local)
 * - GET  /api/orders/{id}        -> detalle
 * - POST /api/orders             -> crear pedido (alumno)
 * - POST /api/orders/{id}/cancel -> cancelar (alumno dueño del pedido o dueño del local)
 * - POST /api/orders/{id}/status -> avanzar estado (dueño)
 */
public class OrderServlet extends ApiServlet {

    private final OrderRepository orders = new OrderRepository();

    @Override
    protected void handle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ApiException {
        String[] s = segments(req);
        switch (req.getMethod()) {
            case "GET" -> get(req, resp, s);
            case "POST" -> post(req, resp, s);
            default -> methodNotAllowed();
        }
    }

    private void get(HttpServletRequest req, HttpServletResponse resp, String[] s)
            throws IOException, SQLException, ApiException {
        String userId = requireAuth(req);
        String role = AuthContext.role(req);
        if (s.length == 0) {
            Responses.ok(resp, orders.listForUser(userId, role));
        } else if (s.length == 1) {
            Responses.ok(resp, orders.byId(userId, role, s[0]));
        } else {
            throw ApiException.notFound("Recurso no encontrado.");
        }
    }

    private void post(HttpServletRequest req, HttpServletResponse resp, String[] s)
            throws IOException, SQLException, ApiException {
        if (s.length == 0) {
            requireStudent(req);
            JSONObject placed = orders.placeOrder(AuthContext.userId(req), readBody(req));
            Responses.created(resp, placed);
        } else if (s.length == 2 && "cancel".equals(s[1])) {
            String userId = requireAuth(req);
            Responses.ok(resp, orders.cancel(userId, AuthContext.role(req), s[0]));
        } else if (s.length == 2 && "status".equals(s[1])) {
            requireOwner(req);
            JSONObject body = readBody(req);
            String newStatus = body.optString("p_new_status", null);
            if (newStatus == null) {
                throw ApiException.badRequest("Falta el nuevo estado.");
            }
            Responses.ok(resp, orders.updateStatus(AuthContext.userId(req), s[0], newStatus));
        } else {
            throw ApiException.notFound("Recurso no encontrado.");
        }
    }
}
