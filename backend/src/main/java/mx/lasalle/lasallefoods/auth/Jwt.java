package mx.lasalle.lasallefoods.auth;

import mx.lasalle.lasallefoods.config.AppConfig;
import org.json.JSONObject;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.Base64;

/**
 * Implementación mínima de JWT firmados con HMAC-SHA256 (HS256). Sin
 * dependencias externas: solo javax.crypto + Base64URL. Suficiente para
 * autenticar las peticiones de la app.
 */
public final class Jwt {

    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder B64D = Base64.getUrlDecoder();

    private Jwt() {
    }

    /** Token firmado con los claims sub (userId), email, role y exp. */
    public static String create(String userId, String email, String role) {
        long now = Instant.now().getEpochSecond();
        long exp = now + AppConfig.accessTokenTtlSeconds();

        String header = B64.encodeToString(
                new JSONObject().put("alg", "HS256").put("typ", "JWT")
                        .toString().getBytes(StandardCharsets.UTF_8));

        String payload = B64.encodeToString(
                new JSONObject()
                        .put("sub", userId)
                        .put("email", email == null ? JSONObject.NULL : email)
                        .put("role", role)
                        .put("iat", now)
                        .put("exp", exp)
                        .toString().getBytes(StandardCharsets.UTF_8));

        String signingInput = header + "." + payload;
        String signature = sign(signingInput);
        return signingInput + "." + signature;
    }

    /** Verifica firma y expiración. Devuelve los claims o null si es inválido. */
    public static Claims verify(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        String[] parts = token.split("\\.");
        if (parts.length != 3) {
            return null;
        }
        String signingInput = parts[0] + "." + parts[1];
        String expected = sign(signingInput);
        if (!constantTimeEquals(expected, parts[2])) {
            return null;
        }
        try {
            JSONObject payload = new JSONObject(
                    new String(B64D.decode(parts[1]), StandardCharsets.UTF_8));
            long exp = payload.optLong("exp", 0);
            if (exp > 0 && Instant.now().getEpochSecond() > exp) {
                return null;
            }
            String sub = payload.optString("sub", null);
            if (sub == null) {
                return null;
            }
            String email = payload.isNull("email") ? null : payload.optString("email", null);
            String role = payload.optString("role", null);
            return new Claims(sub, email, role);
        } catch (Exception e) {
            return null;
        }
    }

    private static String sign(String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(
                    AppConfig.jwtSecret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] raw = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return B64.encodeToString(raw);
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo firmar el JWT", e);
        }
    }

    private static boolean constantTimeEquals(String a, String b) {
        return MessageDigest.isEqual(
                a.getBytes(StandardCharsets.UTF_8),
                b.getBytes(StandardCharsets.UTF_8));
    }

    /** Claims relevantes extraídos del token. */
    public record Claims(String userId, String email, String role) {
    }
}
