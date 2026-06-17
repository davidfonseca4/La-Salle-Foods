package mx.lasalle.lasallefoods.web;

/**
 * Error de negocio o de validación que se traduce a una respuesta HTTP con
 * cuerpo JSON {@code {"code": "...", "message": "..."}}.
 *
 * Los códigos son los que la app SwiftUI ya sabe traducir
 * (23505 duplicado, 42501 sin permiso, 23502/23514 datos inválidos) además
 * de "P0001" para mensajes de negocio ya redactados en español.
 */
public class ApiException extends RuntimeException {

    private final int status;
    private final String code;

    public ApiException(int status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public int status() {
        return status;
    }

    public String code() {
        return code;
    }

    // --- Fábricas de uso común ---

    /** 400 con mensaje de negocio en español (código P0001). */
    public static ApiException badRequest(String message) {
        return new ApiException(400, "P0001", message);
    }

    public static ApiException invalidData(String message) {
        return new ApiException(400, "23514", message);
    }

    public static ApiException unauthorized(String message) {
        return new ApiException(401, "401", message);
    }

    /** 403 — sin permiso para la acción (42501). */
    public static ApiException forbidden(String message) {
        return new ApiException(403, "42501", message);
    }

    public static ApiException notFound(String message) {
        return new ApiException(404, "404", message);
    }

    public static ApiException conflict(String message) {
        return new ApiException(409, "23505", message);
    }
}
