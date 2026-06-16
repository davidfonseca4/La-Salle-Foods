Reglas de negocio — La Salle Foods
Registro y acceso
Solo correos institucionales @lasallebajio.edu.mx pueden registrarse en el sistema.
Al registrarse, el rol se asigna como student (alumno) por defecto; puede indicarse owner (dueño) en el momento del registro, pero no después.
El rol nunca puede modificarse una vez creada la cuenta — cualquier intento de cambio es bloqueado automáticamente.
Perfil
Cada usuario solo puede ver su propio perfil; no puede consultar el de otros.
Cada usuario solo puede editar su propio perfil (por ejemplo, su nombre completo).
Aunque un usuario edite su perfil, el rol permanece fijo (no puede cambiarse ni siquiera a través de una actualización directa).
Catálogo — Categorías y etiquetas
Cualquier persona, incluso sin iniciar sesión, puede ver las categorías de restaurantes, las categorías de productos y las etiquetas disponibles.
Cualquier persona puede ver las etiquetas asignadas a cualquier restaurante.
Restaurantes
Cualquier persona, incluso sin sesión, puede ver los restaurantes que están activos (is_active = true).
Un dueño siempre puede ver su propio restaurante, aunque esté marcado como inactivo.
Solo un usuario con rol owner puede crear un restaurante, y debe registrarse a sí mismo como dueño (owner_id).
Cada dueño solo puede tener un restaurante — la base de datos impide tener más de uno.
Solo el dueño puede editar los datos de su propio restaurante.
No es posible eliminar un restaurante desde la aplicación cliente — no existe esa operación habilitada.
Productos
Cualquier persona, incluso sin sesión, puede ver los productos de los restaurantes activos.
Solo el dueño puede crear, editar o eliminar productos de su propio restaurante — no puede tocar los de otro restaurante.
Pedidos
Solo un alumno autenticado (role = student) puede crear un pedido.
El restaurante debe estar activo al momento de hacer el pedido.
Solo se pueden incluir en el pedido productos que estén disponibles (is_available = true) y que pertenezcan al restaurante seleccionado.
Al crearse el pedido, se asigna automáticamente un código de recogida (una letra seguida de dos dígitos, generado aleatoriamente) y un folio único con prefijo LSF- más número secuencial.
Todo pedido comienza en estado pendiente.
Un alumno solo puede ver sus propios pedidos y sus líneas de detalle.
Un dueño solo puede ver los pedidos de su restaurante y sus líneas de detalle.
Solo el alumno que hizo el pedido puede cancelarlo, y únicamente si todavía está en estado pendiente.
El dueño puede avanzar el estado de un pedido siguiendo esta secuencia estricta y sin saltos:
pendiente → preparando → listo → completado
No se permiten retrocesos ni transiciones distintas a las descritas.
Notificaciones
Cada usuario solo puede ver sus propias notificaciones.
Cuando un alumno hace un nuevo pedido, el dueño del restaurante recibe automáticamente una notificación.
Cada vez que el estado de un pedido cambia, se envía automáticamente una notificación al destinatario correspondiente.
Un usuario solo puede marcar como leída una notificación que le pertenece; no puede marcar las de otros.
No existe operación de inserción directa de notificaciones desde el cliente — solo se crean mediante los eventos automáticos del sistema.
Restricciones de datos
El precio de un producto no puede ser negativo (mínimo 0).
El precio unitario registrado en una línea de pedido no puede ser negativo (mínimo 0).
La cantidad de un producto en una línea de pedido debe ser al menos 1.
El tiempo mínimo de preparación de un restaurante debe ser mayor a 0 minutos.
El rating de un restaurante debe estar entre 0 y 5 (inclusive).
El conteo de reseñas de un restaurante no puede ser negativo.
El color de portada de un restaurante debe ser un código hexadecimal válido de 6 dígitos (formato #RRGGBB).
Los nombres de categorías de restaurante, categorías de producto y etiquetas son únicos en toda la plataforma.