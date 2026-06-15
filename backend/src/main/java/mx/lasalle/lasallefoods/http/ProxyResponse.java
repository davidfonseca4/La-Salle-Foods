package mx.lasalle.lasallefoods.http;

import java.net.http.HttpHeaders;

/**
 * Resultado de reenviar una peticion a Supabase: status, headers y body
 * crudos, listos para copiarse a la HttpServletResponse del cliente.
 */
public record ProxyResponse(int status, HttpHeaders headers, byte[] body) {
}
