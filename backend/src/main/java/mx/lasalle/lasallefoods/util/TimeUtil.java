package mx.lasalle.lasallefoods.util;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.Calendar;
import java.util.TimeZone;

/**
 * Formateo de marcas de tiempo a ISO-8601 en UTC, compatible con el
 * decodificador de fechas de la app SwiftUI (admite fracciones de segundo y
 * el sufijo 'Z').
 */
public final class TimeUtil {

    /** Calendario UTC reutilizable para leer/escribir DATETIME sin desfase. */
    public static final Calendar UTC = Calendar.getInstance(TimeZone.getTimeZone("UTC"));

    private static final DateTimeFormatter ISO =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC);

    private TimeUtil() {
    }

    public static String iso(Timestamp ts) {
        if (ts == null) {
            return null;
        }
        return ISO.format(ts.toInstant());
    }

    public static String nowIso() {
        return ISO.format(Instant.now());
    }
}
