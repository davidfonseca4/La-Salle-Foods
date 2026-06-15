package mx.lasalle.lasallefoods.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.lasalle.lasallefoods.config.SupabaseConfig;
import mx.lasalle.lasallefoods.http.ProxyResponse;
import mx.lasalle.lasallefoods.http.SupabaseGateway;

import java.io.IOException;

/**
 * Fachada de perfil: /api/profile.
 *
 * - GET   /api/profile -> /rest/v1/profiles?select=*  (RLS limita a id = auth.uid())
 * - PATCH /api/profile -> /rest/v1/profiles?id=eq.{uid}  body: { "full_name": "..." }
 *
 * El {uid} se obtiene llamando a {SUPABASE_URL}/auth/v1/user con el
 * Authorization del cliente (mismo patron que AuthServlet /api/auth/me).
 *
 * Mapeo declarado en web.xml.
 */
public class ProfileServlet extends HttpServlet {

    private SupabaseGateway gateway;

    @Override
    public void init() throws ServletException {
        gateway = new SupabaseGateway(SupabaseConfig.url(), SupabaseConfig.anonKey());
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String auth = req.getHeader("Authorization");

        try {
            switch (req.getMethod()) {
                case "GET" -> {
                    ProxyResponse upstream = gateway.forward("GET", "/rest/v1/profiles", "select=*", auth, null, null);
                    writeProxyResponse(resp, upstream);
                }
                case "PATCH" -> {
                    ProxyResponse userResponse = gateway.fetchCurrentUser(auth);
                    String uid = SupabaseGateway.extractUserId(userResponse);
                    if (uid == null) {
                        writeProxyResponse(resp, userResponse);
                        return;
                    }
                    byte[] body = req.getInputStream().readAllBytes();
                    ProxyResponse upstream = gateway.forward("PATCH", "/rest/v1/profiles",
                            "id=eq." + uid, auth, body, req.getContentType());
                    writeProxyResponse(resp, upstream);
                }
                default -> resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Upstream interrupted");
        }
    }

    private void writeProxyResponse(HttpServletResponse resp, ProxyResponse upstream) throws IOException {
        resp.setStatus(upstream.status());
        resp.setContentType("application/json");
        resp.getOutputStream().write(upstream.body());
    }
}
