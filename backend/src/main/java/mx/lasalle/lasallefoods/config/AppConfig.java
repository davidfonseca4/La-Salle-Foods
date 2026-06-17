package mx.lasalle.lasallefoods.config;

/**
 * Configuración del backend leída de variables de entorno, con valores por
 * defecto pensados para desarrollo local (MySQL en localhost). En producción
 * (Azure) todas se inyectan como variables de entorno del contenedor.
 */
public final class AppConfig {

    private AppConfig() {
    }

    private static String env(String key, String fallback) {
        String value = System.getenv(key);
        return (value == null || value.isBlank()) ? fallback : value;
    }

    // --- Base de datos MySQL ---

    public static String dbUrl() {
        return env("DB_URL",
                "jdbc:mysql://localhost:3306/lasallefoods"
                        + "?useSSL=false&allowPublicKeyRetrieval=true"
                        + "&serverTimezone=UTC&characterEncoding=utf8");
    }

    public static String dbUser() {
        return env("DB_USER", "root");
    }

    public static String dbPassword() {
        return env("DB_PASSWORD", "");
    }

    public static int dbPoolSize() {
        try {
            return Integer.parseInt(env("DB_POOL_SIZE", "5"));
        } catch (NumberFormatException e) {
            return 5;
        }
    }

    // --- Seguridad / sesiones ---

    /** Secreto para firmar los JWT (HS256). DEBE configurarse en producción. */
    public static String jwtSecret() {
        return env("JWT_SECRET",
                "dev-secret-cambia-esto-en-produccion-0123456789abcdef");
    }

    /** Vida del access token en segundos (por defecto 1 hora). */
    public static long accessTokenTtlSeconds() {
        try {
            return Long.parseLong(env("ACCESS_TOKEN_TTL", "3600"));
        } catch (NumberFormatException e) {
            return 3600;
        }
    }

    /** Vida del refresh token en segundos (por defecto 30 días). */
    public static long refreshTokenTtlSeconds() {
        try {
            return Long.parseLong(env("REFRESH_TOKEN_TTL", "2592000"));
        } catch (NumberFormatException e) {
            return 2592000;
        }
    }

    // --- Reglas de negocio ---

    /** Dominio institucional permitido para registrarse. */
    public static String institutionalDomain() {
        return env("INSTITUTIONAL_DOMAIN", "@lasallebajio.edu.mx");
    }

    /** Si se deben crear datos de demostración al arrancar (true por defecto). */
    public static boolean seedOnStartup() {
        return Boolean.parseBoolean(env("SEED_ON_STARTUP", "true"));
    }
}
