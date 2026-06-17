package mx.lasalle.lasallefoods.web;

import jakarta.servlet.http.HttpServletResponse;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/** Utilidades para escribir respuestas JSON consistentes. */
public final class Responses {

    private Responses() {
    }

    public static void json(HttpServletResponse resp, int status, Object body) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json; charset=UTF-8");
        String text = body == null ? "null" : body.toString();
        resp.getOutputStream().write(text.getBytes(StandardCharsets.UTF_8));
    }

    public static void ok(HttpServletResponse resp, JSONObject body) throws IOException {
        json(resp, 200, body);
    }

    public static void ok(HttpServletResponse resp, JSONArray body) throws IOException {
        json(resp, 200, body);
    }

    public static void created(HttpServletResponse resp, JSONObject body) throws IOException {
        json(resp, 201, body);
    }

    public static void noContent(HttpServletResponse resp) {
        resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
    }

    public static void error(HttpServletResponse resp, ApiException ex) throws IOException {
        JSONObject body = new JSONObject()
                .put("code", ex.code())
                .put("message", ex.getMessage());
        json(resp, ex.status(), body);
    }

    public static void error(HttpServletResponse resp, int status, String code, String message) throws IOException {
        JSONObject body = new JSONObject().put("code", code).put("message", message);
        json(resp, status, body);
    }
}
