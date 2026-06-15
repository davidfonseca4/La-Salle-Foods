package mx.lasalle.lasallefoods.http;

import org.json.JSONObject;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;

/**
 * Reenvia peticiones HTTP a Supabase (Auth o PostgREST), agregando el header
 * apikey desde la configuracion del servidor y propagando el Authorization
 * del cliente tal cual (RLS depende de auth.uid()).
 */
public class SupabaseGateway {

    private final HttpClient client = HttpClient.newHttpClient();
    private final String baseUrl;
    private final String anonKey;

    public SupabaseGateway(String baseUrl, String anonKey) {
        this.baseUrl = baseUrl;
        this.anonKey = anonKey;
    }

    public ProxyResponse forward(String method, String path, String query,
                                  String authorizationHeader,
                                  byte[] body, String contentType) throws IOException, InterruptedException {
        String uriString = baseUrl + path + (query != null ? "?" + query : "");
        URI uri = URI.create(uriString);

        HttpRequest.Builder builder = HttpRequest.newBuilder(uri)
                .header("apikey", anonKey)
                .header("Content-Type", contentType != null ? contentType : "application/json");

        if (authorizationHeader != null) {
            builder.header("Authorization", authorizationHeader);
        }

        HttpRequest.BodyPublisher publisher = (body == null || body.length == 0)
                ? HttpRequest.BodyPublishers.noBody()
                : HttpRequest.BodyPublishers.ofByteArray(body);

        builder.method(method, publisher);

        HttpResponse<byte[]> response = client.send(builder.build(), HttpResponse.BodyHandlers.ofByteArray());
        return new ProxyResponse(response.statusCode(), response.headers(), response.body());
    }

    /**
     * Resuelve el id (uuid) del usuario autenticado llamando a
     * {SUPABASE_URL}/auth/v1/user con el Authorization recibido del cliente.
     *
     * Devuelve null si la respuesta no fue 200 o no contiene "id"; en ese
     * caso el llamador debe propagar la ProxyResponse de error obtenida con
     * forward(...) directamente al cliente.
     */
    public ProxyResponse fetchCurrentUser(String authorizationHeader) throws IOException, InterruptedException {
        return forward("GET", "/auth/v1/user", null, authorizationHeader, null, null);
    }

    public static String extractUserId(ProxyResponse userResponse) {
        if (userResponse.status() != 200) {
            return null;
        }
        JSONObject json = new JSONObject(new String(userResponse.body(), StandardCharsets.UTF_8));
        return json.has("id") ? json.getString("id") : null;
    }
}
