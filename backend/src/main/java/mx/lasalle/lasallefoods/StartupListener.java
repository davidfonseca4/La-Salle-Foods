package mx.lasalle.lasallefoods;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import mx.lasalle.lasallefoods.config.AppConfig;
import mx.lasalle.lasallefoods.db.Db;
import mx.lasalle.lasallefoods.db.Seeder;

import java.util.TimeZone;

/**
 * Inicialización del backend al desplegar:
 *   1. Fija la zona horaria de la JVM en UTC para que todas las marcas de
 *      tiempo (DATETIME en MySQL ↔ JSON) sean consistentes.
 *   2. Siembra datos de demostración si la base está vacía.
 *   3. Cierra el pool de conexiones al apagar.
 */
@WebListener
public class StartupListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
        if (AppConfig.seedOnStartup()) {
            try {
                Seeder.seed();
            } catch (Exception e) {
                System.out.println("[Startup] No se pudo sembrar datos: " + e.getMessage());
            }
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        Db.close();
    }
}
