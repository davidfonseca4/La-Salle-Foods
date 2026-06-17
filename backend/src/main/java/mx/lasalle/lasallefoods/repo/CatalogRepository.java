package mx.lasalle.lasallefoods.repo;

import mx.lasalle.lasallefoods.db.Db;
import org.json.JSONArray;
import org.json.JSONObject;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/** Catálogos fijos de solo lectura: categorías de local/producto y etiquetas. */
public final class CatalogRepository {

    public JSONArray restaurantCategories() throws SQLException {
        return query("SELECT id, name FROM restaurant_categories ORDER BY name", false);
    }

    public JSONArray productCategories() throws SQLException {
        return query("SELECT id, name, sort_order FROM product_categories ORDER BY sort_order", true);
    }

    public JSONArray tags() throws SQLException {
        return query("SELECT id, name FROM tags ORDER BY name", false);
    }

    private JSONArray query(String sql, boolean includeSortOrder) throws SQLException {
        try (Connection conn = Db.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            JSONArray array = new JSONArray();
            while (rs.next()) {
                JSONObject row = new JSONObject()
                        .put("id", rs.getInt("id"))
                        .put("name", rs.getString("name"));
                if (includeSortOrder) {
                    row.put("sort_order", rs.getInt("sort_order"));
                }
                array.put(row);
            }
            return array;
        }
    }
}
