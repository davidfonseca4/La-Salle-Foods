package mx.lasalle.lasallefoods.auth;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Acceso al usuario autenticado de la petición actual. El {@code AuthFilter}
 * coloca los datos del JWT como atributos del request; aquí se leen de forma
 * tipada. Si no hay sesión, los getters devuelven {@code null}.
 */
public final class AuthContext {

    public static final String ATTR_USER_ID = "auth.userId";
    public static final String ATTR_ROLE = "auth.role";
    public static final String ATTR_EMAIL = "auth.email";

    private AuthContext() {
    }

    public static String userId(HttpServletRequest req) {
        Object value = req.getAttribute(ATTR_USER_ID);
        return value == null ? null : value.toString();
    }

    public static String role(HttpServletRequest req) {
        Object value = req.getAttribute(ATTR_ROLE);
        return value == null ? null : value.toString();
    }

    public static String email(HttpServletRequest req) {
        Object value = req.getAttribute(ATTR_EMAIL);
        return value == null ? null : value.toString();
    }

    public static boolean isAuthenticated(HttpServletRequest req) {
        return userId(req) != null;
    }

    public static boolean isOwner(HttpServletRequest req) {
        return "owner".equals(role(req));
    }

    public static boolean isStudent(HttpServletRequest req) {
        return "student".equals(role(req));
    }
}
