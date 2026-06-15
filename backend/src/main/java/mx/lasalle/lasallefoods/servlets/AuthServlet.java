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
 * Proxy de autenticacion: /api/auth/* -> {SUPABASE_URL}/auth/v1/*.
 *
 * El backend no implementa su propio sistema de usuarios; solo reenvia
 * a Supabase Auth (GoTrue) agregando el header apikey y propagando el
 * body / Authorization / status code tal cual.
 *
 * Mapeo declarado en web.xml.
 */
public class AuthServlet extends HttpServlet {

    private SupabaseGateway gateway;

    @Override
    public void init() throws ServletException {
        gateway = new SupabaseGateway(SupabaseConfig.url(), SupabaseConfig.anonKey());
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String subPath = req.getPathInfo();
        if (subPath == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String authPath;
        String query = req.getQueryString();

        switch (subPath) {
            case "/register" -> authPath = "/auth/v1/signup";
            case "/login" -> {
                authPath = "/auth/v1/token";
                query = "grant_type=password";
            }
            case "/refresh" -> {
                authPath = "/auth/v1/token";
                query = "grant_type=refresh_token";
            }
            case "/me" -> authPath = "/auth/v1/user";
            case "/logout" -> authPath = "/auth/v1/logout";
            case "/recover" -> authPath = "/auth/v1/recover";
            default -> {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
        }

        String auth = req.getHeader("Authorization");
        byte[] body = req.getInputStream().readAllBytes();

        try {
            ProxyResponse upstream = gateway.forward(
                    req.getMethod(), authPath, query, auth, body, req.getContentType());

            resp.setStatus(upstream.status());
            resp.setContentType("application/json");
            resp.getOutputStream().write(upstream.body());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Upstream interrupted");
        }
    }
}
