package mx.lasalle.lasallefoods.db;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import mx.lasalle.lasallefoods.config.AppConfig;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * Punto único de acceso al pool de conexiones (HikariCP) hacia MySQL.
 * El pool se inicializa de forma perezosa la primera vez que se solicita
 * una conexión y se reutiliza durante toda la vida de la aplicación.
 */
public final class Db {

    private static volatile HikariDataSource dataSource;

    private Db() {
    }

    private static HikariDataSource dataSource() {
        HikariDataSource local = dataSource;
        if (local == null) {
            synchronized (Db.class) {
                local = dataSource;
                if (local == null) {
                    HikariConfig config = new HikariConfig();
                    // Forzar la carga del driver: en Tomcat el registro
                    // automático por SPI no siempre ocurre en el classloader
                    // de la webapp, y HikariCP falla con "Failed to get driver".
                    config.setDriverClassName("com.mysql.cj.jdbc.Driver");
                    config.setJdbcUrl(AppConfig.dbUrl());
                    config.setUsername(AppConfig.dbUser());
                    config.setPassword(AppConfig.dbPassword());
                    config.setMaximumPoolSize(AppConfig.dbPoolSize());
                    config.setPoolName("lasallefoods-pool");
                    config.setConnectionTimeout(10_000);
                    config.setInitializationFailTimeout(-1); // no fallar el arranque si MySQL aún no está
                    dataSource = local = new HikariDataSource(config);
                }
            }
        }
        return local;
    }

    /** Devuelve una conexión del pool (recuérdese cerrarla con try-with-resources). */
    public static Connection getConnection() throws SQLException {
        return dataSource().getConnection();
    }

    public static void close() {
        if (dataSource != null) {
            dataSource.close();
            dataSource = null;
        }
    }
}
