package mx.lasalle.lasallefoods.repo;

import mx.lasalle.lasallefoods.auth.Jwt;
import mx.lasalle.lasallefoods.auth.Passwords;
import mx.lasalle.lasallefoods.config.AppConfig;
import mx.lasalle.lasallefoods.db.Db;
import mx.lasalle.lasallefoods.util.Ids;
import mx.lasalle.lasallefoods.web.ApiException;
import org.json.JSONArray;
import org.json.JSONObject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;

/**
 * Acceso a usuarios, perfiles y tokens de refresco. Concentra toda la lógica
 * de autenticación (registro/login/refresh/logout) y la lectura/edición del
 * perfil propio.
 */
public final class AuthRepository {

    /** Registro de una cuenta nueva. Devuelve la sesión (tokens + usuario). */
    public JSONObject register(String email, String password, String fullName, String role)
            throws SQLException, ApiException {

        String normalizedEmail = email == null ? "" : email.trim().toLowerCase();
        if (!normalizedEmail.endsWith(AppConfig.institutionalDomain().toLowerCase())) {
            throw ApiException.badRequest(
                    "Usa tu correo institucional " + AppConfig.institutionalDomain());
        }
        if (password == null || password.length() < 6) {
            throw ApiException.badRequest("La contraseña debe tener al menos 6 caracteres.");
        }
        if (fullName == null || fullName.isBlank()) {
            throw ApiException.badRequest("El nombre es obligatorio.");
        }
        String safeRole = "owner".equals(role) ? "owner" : "student";
        String userId = Ids.uuid();
        String hash = Passwords.hash(password);

        try (Connection conn = Db.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO users (id, email, password_hash) VALUES (?, ?, ?)")) {
                    ps.setString(1, userId);
                    ps.setString(2, normalizedEmail);
                    ps.setString(3, hash);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO profiles (id, full_name, role) VALUES (?, ?, ?)")) {
                    ps.setString(1, userId);
                    ps.setString(2, fullName.trim());
                    ps.setString(3, safeRole);
                    ps.executeUpdate();
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                if (e.getMessage() != null && e.getMessage().contains("Duplicate entry")) {
                    throw ApiException.conflict("Ya existe una cuenta con ese correo.");
                }
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }

            return buildSession(conn, userId, normalizedEmail, safeRole);
        }
    }

    /** Inicio de sesión con correo y contraseña. */
    public JSONObject login(String email, String password) throws SQLException, ApiException {
        String normalizedEmail = email == null ? "" : email.trim().toLowerCase();
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT u.id, u.email, u.password_hash, p.role "
                             + "FROM users u JOIN profiles p ON p.id = u.id WHERE u.email = ?")) {
            ps.setString(1, normalizedEmail);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next() || !Passwords.matches(password, rs.getString("password_hash"))) {
                    throw ApiException.badRequest("Correo o contraseña incorrectos.");
                }
                return buildSession(conn, rs.getString("id"), rs.getString("email"), rs.getString("role"));
            }
        }
    }

    /** Renueva la sesión a partir de un refresh token válido (lo rota). */
    public JSONObject refresh(String refreshToken) throws SQLException, ApiException {
        if (refreshToken == null || refreshToken.isBlank()) {
            throw ApiException.unauthorized("Sesión inválida.");
        }
        try (Connection conn = Db.getConnection()) {
            String userId;
            String email;
            String role;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT rt.user_id, rt.expires_at, u.email, p.role "
                            + "FROM refresh_tokens rt "
                            + "JOIN users u ON u.id = rt.user_id "
                            + "JOIN profiles p ON p.id = rt.user_id "
                            + "WHERE rt.token = ?")) {
                ps.setString(1, refreshToken);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw ApiException.unauthorized("Sesión inválida.");
                    }
                    Timestamp expires = rs.getTimestamp("expires_at");
                    if (expires != null && expires.toInstant().isBefore(Instant.now())) {
                        throw ApiException.unauthorized("Tu sesión expiró.");
                    }
                    userId = rs.getString("user_id");
                    email = rs.getString("email");
                    role = rs.getString("role");
                }
            }
            // Rotación: invalida el token usado.
            try (PreparedStatement del = conn.prepareStatement(
                    "DELETE FROM refresh_tokens WHERE token = ?")) {
                del.setString(1, refreshToken);
                del.executeUpdate();
            }
            return buildSession(conn, userId, email, role);
        }
    }

    /** Cierra la sesión invalidando todos los refresh tokens del usuario. */
    public void logout(String userId) throws SQLException {
        if (userId == null) {
            return;
        }
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "DELETE FROM refresh_tokens WHERE user_id = ?")) {
            ps.setString(1, userId);
            ps.executeUpdate();
        }
    }

    /** Datos básicos del usuario autenticado: {id, email}. */
    public JSONObject me(String userId) throws SQLException, ApiException {
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT id, email FROM users WHERE id = ?")) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw ApiException.notFound("Usuario no encontrado.");
                }
                return new JSONObject()
                        .put("id", rs.getString("id"))
                        .put("email", rs.getString("email"));
            }
        }
    }

    /** Perfil propio como arreglo (formato de GET /api/profile). */
    public JSONArray profile(String userId) throws SQLException {
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT p.id, p.full_name, p.role, u.email "
                             + "FROM profiles p JOIN users u ON u.id = p.id WHERE p.id = ?")) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                JSONArray array = new JSONArray();
                if (rs.next()) {
                    array.put(new JSONObject()
                            .put("id", rs.getString("id"))
                            .put("full_name", rs.getString("full_name"))
                            .put("role", rs.getString("role"))
                            .put("email", rs.getString("email")));
                }
                return array;
            }
        }
    }

    /** Actualiza únicamente el nombre del perfil propio (el rol es inmutable). */
    public void updateFullName(String userId, String fullName) throws SQLException, ApiException {
        if (fullName == null || fullName.isBlank()) {
            throw ApiException.badRequest("El nombre no puede estar vacío.");
        }
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE profiles SET full_name = ? WHERE id = ?")) {
            ps.setString(1, fullName.trim());
            ps.setString(2, userId);
            ps.executeUpdate();
        }
    }

    // --- Privado ---

    private JSONObject buildSession(Connection conn, String userId, String email, String role)
            throws SQLException {
        String accessToken = Jwt.create(userId, email, role);
        String refreshToken = Ids.uuid();
        Timestamp expires = Timestamp.from(
                Instant.now().plusSeconds(AppConfig.refreshTokenTtlSeconds()));

        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO refresh_tokens (token, user_id, expires_at) VALUES (?, ?, ?)")) {
            ps.setString(1, refreshToken);
            ps.setString(2, userId);
            ps.setTimestamp(3, expires);
            ps.executeUpdate();
        }

        return new JSONObject()
                .put("access_token", accessToken)
                .put("refresh_token", refreshToken)
                .put("token_type", "bearer")
                .put("user", new JSONObject().put("id", userId).put("email", email));
    }
}
