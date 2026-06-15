package mx.lasalle.lasallefoods.filters;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.logging.Logger;

/**
 * Filtro de logging para /api/*: registra metodo, path, status y latencia
 * en milisegundos de cada peticion.
 *
 * Mapeo declarado en web.xml.
 */
public class LoggingFilter extends HttpFilter {

    private static final Logger LOG = Logger.getLogger(LoggingFilter.class.getName());

    @Override
    protected void doFilter(HttpServletRequest req, HttpServletResponse resp, FilterChain chain)
            throws IOException, ServletException {
        long start = System.currentTimeMillis();
        try {
            chain.doFilter(req, resp);
        } finally {
            long elapsedMs = System.currentTimeMillis() - start;
            String path = req.getRequestURI();
            if (req.getQueryString() != null) {
                path += "?" + req.getQueryString();
            }
            LOG.info(String.format("%s %s -> %d (%d ms)", req.getMethod(), path, resp.getStatus(), elapsedMs));
        }
    }
}
