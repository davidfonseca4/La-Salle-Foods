package mx.lasalle.lasallefoods.db;

import mx.lasalle.lasallefoods.auth.Passwords;
import mx.lasalle.lasallefoods.util.Ids;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Siembra datos de demostración (un dueño con su local y productos, y un
 * alumno) la primera vez que el backend arranca contra una base vacía. Es
 * idempotente: si ya existen restaurantes, no hace nada.
 *
 * Cuentas demo (contraseña: LaSalle2026!):
 *   - Dueño:  donamary@lasallebajio.edu.mx
 *   - Alumno: alumno@lasallebajio.edu.mx
 */
public final class Seeder {

    private static final String DEMO_PASSWORD = "LaSalle2026!";

    private Seeder() {
    }

    public static void seed() {
        try (Connection conn = Db.getConnection()) {
            if (count(conn, "restaurants") > 0) {
                return; // ya sembrado
            }

            String ownerId = ensureUser(conn,
                    "donamary@lasallebajio.edu.mx", "María (Tortas Doña Mary)", "owner");
            ensureUser(conn, "alumno@lasallebajio.edu.mx", "Alumno Demo", "student");

            int categoryMexicana = categoryId(conn, "restaurant_categories", "Mexicana");

            String restaurantId = Ids.uuid();
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO restaurants (id, owner_id, category_id, name, description, location, "
                            + "symbol, cover_color, rating, review_count, prep_time_min, prep_time_max) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
                ps.setString(1, restaurantId);
                ps.setString(2, ownerId);
                ps.setInt(3, categoryMexicana);
                ps.setString(4, "Tortas Doña Mary");
                ps.setString(5, "Tortas, quesadillas y aguas frescas hechas al momento.");
                ps.setString(6, "Cafetería Central");
                ps.setString(7, "takeoutbag.and.cup.and.straw.fill");
                ps.setString(8, "#E23744");
                ps.setBigDecimal(9, new java.math.BigDecimal("4.6"));
                ps.setInt(10, 128);
                ps.setInt(11, 8);
                ps.setInt(12, 15);
                ps.executeUpdate();
            }

            linkTag(conn, restaurantId, "Sin filas");
            linkTag(conn, restaurantId, "Popular");

            int platillos = categoryId(conn, "product_categories", "Platillos");
            int bebidas = categoryId(conn, "product_categories", "Bebidas");
            int antojitos = categoryId(conn, "product_categories", "Antojitos");
            int postres = categoryId(conn, "product_categories", "Postres");

            addProduct(conn, restaurantId, platillos, "Torta de milanesa",
                    "Milanesa de res con aguacate, jitomate y frijoles.", "65.00", "fork.knife", true);
            addProduct(conn, restaurantId, platillos, "Torta de jamón",
                    "Jamón, queso y aguacate en pan recién horneado.", "48.00", "fork.knife", false);
            addProduct(conn, restaurantId, bebidas, "Agua de horchata",
                    "Agua fresca de horchata 500 ml.", "20.00", "cup.and.saucer.fill", true);
            addProduct(conn, restaurantId, antojitos, "Quesadilla de queso",
                    "Tortilla de maíz con queso Oaxaca.", "35.00", "takeoutbag.and.cup.and.straw.fill", false);
            addProduct(conn, restaurantId, postres, "Flan napolitano",
                    "Flan casero con caramelo.", "30.00", "birthday.cake.fill", false);

            System.out.println("[Seeder] Datos de demostración creados.");
        } catch (SQLException e) {
            System.out.println("[Seeder] Omitido (¿esquema aún no aplicado?): " + e.getMessage());
        }
    }

    private static int count(Connection conn, String table) throws SQLException {
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM " + table)) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    private static String ensureUser(Connection conn, String email, String fullName, String role)
            throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT id FROM users WHERE email = ?")) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("id");
                }
            }
        }
        String id = Ids.uuid();
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO users (id, email, password_hash) VALUES (?, ?, ?)")) {
            ps.setString(1, id);
            ps.setString(2, email);
            ps.setString(3, Passwords.hash(DEMO_PASSWORD));
            ps.executeUpdate();
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO profiles (id, full_name, role) VALUES (?, ?, ?)")) {
            ps.setString(1, id);
            ps.setString(2, fullName);
            ps.setString(3, role);
            ps.executeUpdate();
        }
        return id;
    }

    private static int categoryId(Connection conn, String table, String name) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM " + table + " WHERE name = ?")) {
            ps.setString(1, name);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("id") : 1;
            }
        }
    }

    private static void linkTag(Connection conn, String restaurantId, String tagName) throws SQLException {
        Integer tagId = null;
        try (PreparedStatement ps = conn.prepareStatement("SELECT id FROM tags WHERE name = ?")) {
            ps.setString(1, tagName);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    tagId = rs.getInt("id");
                }
            }
        }
        if (tagId == null) {
            return;
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO restaurant_tags (restaurant_id, tag_id) VALUES (?, ?)")) {
            ps.setString(1, restaurantId);
            ps.setInt(2, tagId);
            ps.executeUpdate();
        }
    }

    private static void addProduct(Connection conn, String restaurantId, int categoryId, String name,
                                   String description, String price, String symbol, boolean popular)
            throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO products (id, restaurant_id, category_id, name, description, price, "
                        + "symbol, is_available, is_popular) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)")) {
            ps.setString(1, Ids.uuid());
            ps.setString(2, restaurantId);
            ps.setInt(3, categoryId);
            ps.setString(4, name);
            ps.setString(5, description);
            ps.setBigDecimal(6, new java.math.BigDecimal(price));
            ps.setString(7, symbol);
            ps.setBoolean(8, popular);
            ps.executeUpdate();
        }
    }
}
