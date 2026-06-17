package mx.lasalle.lasallefoods.util;

import java.security.SecureRandom;
import java.util.UUID;

/** Generadores de identificadores. */
public final class Ids {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final char[] LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ".toCharArray();

    private Ids() {
    }

    public static String uuid() {
        return UUID.randomUUID().toString();
    }

    /** Código de recogida: una letra seguida de dos dígitos (ej. "A12"). */
    public static String pickupCode() {
        char letter = LETTERS[RANDOM.nextInt(LETTERS.length)];
        int number = RANDOM.nextInt(100); // 00–99
        return String.format("%c%02d", letter, number);
    }
}
