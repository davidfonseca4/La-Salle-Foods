package mx.lasalle.lasallefoods.filters;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import mx.lasalle.lasallefoods.auth.AuthContext;
import mx.lasalle.lasallefoods.auth.Jwt;

import java.io.IOException;

/**
 * Lee el header {@code Authorization: Bearer <jwt>} de cada petición a
 * {@code /api/*}. Si el token es válido, expone userId/role/email como
 * atributos del request (vía {@link AuthContext}). No bloquea: la
 * autorización fina la deciden los servlets (endpoints públicos vs. privados).
 */
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;

        String header = req.getHeader("Authorization");
        if (header != null && header.regionMatches(true, 0, "Bearer ", 0, 7)) {
            String token = header.substring(7).trim();
            Jwt.Claims claims = Jwt.verify(token);
            if (claims != null) {
                req.setAttribute(AuthContext.ATTR_USER_ID, claims.userId());
                req.setAttribute(AuthContext.ATTR_ROLE, claims.role());
                req.setAttribute(AuthContext.ATTR_EMAIL, claims.email());
            }
        }

        chain.doFilter(request, response);
    }
}
