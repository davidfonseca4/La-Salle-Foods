package mx.lasalle.lasallefoods.config;

/**
 * Lee la configuracion de conexion a Supabase desde variables de entorno,
 * con valores por defecto apuntando al proyecto actual de La Salle Foods.
 *
 * SUPABASE_ANON_KEY es la clave publica (publishable/anon), nunca la
 * service_role. La seguridad real la da RLS en Supabase.
 */
public final class SupabaseConfig {

    private static final String DEFAULT_URL = "https://pftnnkrpufxpzoadbgxu.supabase.co";
    private static final String DEFAULT_ANON_KEY = "sb_publishable_0PghU_jyiuPHujQnGCqNVw_KudLnah6";

    private SupabaseConfig() {
    }

    public static String url() {
        return System.getenv().getOrDefault("SUPABASE_URL", DEFAULT_URL);
    }

    public static String anonKey() {
        return System.getenv().getOrDefault("SUPABASE_ANON_KEY", DEFAULT_ANON_KEY);
    }
}
