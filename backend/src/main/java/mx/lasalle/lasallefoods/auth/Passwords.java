package mx.lasalle.lasallefoods.auth;

import org.mindrot.jbcrypt.BCrypt;

/** Hash y verificación de contraseñas con BCrypt. */
public final class Passwords {

    private Passwords() {
    }

    public static String hash(String plain) {
        return BCrypt.hashpw(plain, BCrypt.gensalt(10));
    }

    public static boolean matches(String plain, String hash) {
        if (plain == null || hash == null || hash.isBlank()) {
            return false;
        }
        try {
            return BCrypt.checkpw(plain, hash);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
