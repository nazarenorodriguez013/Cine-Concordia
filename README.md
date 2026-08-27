# Cine Concordia

Plataforma web de venta de entradas online para cines. Permite al cine gestionar y publicar sus funciones, mientras que los usuarios pueden consultar la cartelera, elegir función y horario, seleccionar butacas y comprar entradas de forma online.

Proyecto de la materia Programación 4.

## Equipo

- Leonardo Mover
- Santiago Jacobo
- Nazareno Rodriguez
- Valentin Reboli

## Características principales

- Consulta de cartelera y disponibilidad de asientos en tiempo real
- Compra de entradas online con selección de butacas
- Entradas digitales con código QR enviadas por Telegram y email
- Marketing y notificaciones por WhatsApp y email
- Panel administrativo para gestionar funciones, películas, salas, horarios y promociones

## Estructura de base de datos

### Tablas

- **usuarios**: cuentas de usuario. `id` (SERIAL PK), `nombre`, `apellido`, `correo` (unique), `telefono`, `password_hash`, `rol` (CLIENTE/ADMIN/EMPLEADO, default), `creado_en`, `actualizado_en`.
- **generos**: categorías de películas. `id` (SERIAL PK), `nombre` (unique VARCHAR).
- **peliculas**: `id`, `titulo`, `sinopsis`, `duracion_min`, `clasificacion`, `poster_url`, `backdrop_url`, `trailer_url`, `en_cartelera` (boolean), `fecha_estreno`, `activa` (boolean), timestamps.
- **pelicula_generos**: tabla intermedia película↔género. `pelicula_id` (FK), `genero_id` (FK), clave primaria compuesta.
- **salas**: `id`, `nombre`, `filas`, `columnas`, `capacidad_total`, `activa` (boolean).
- **butacas**: `id`, `sala_id` (FK), `fila` (letra), `numero`, `tipo` (STANDARD/VIP/ACCESIBLE/INHABILITADA); unique en (`sala_id`, `fila`, `numero`).
- **funciones**: `pelicula_id` (FK), `sala_id` (FK), `fecha_hora`, `formato` (2D/3D/ATMOS), `idioma` (DOB/SUB), `precio_base`, `cancelada`.
- **tipos_entrada**: `id`, `nombre` (unique), `ajuste_precio`, `activo` (boolean).
- **reservas**: `usuario_id` (nullable), `funcion_id` (FK), datos de contacto de invitado, `total`, `estado` (PENDIENTE/PAGADA/CANCELADA/EXPIRADA), `codigo_qr`.
- **reserva_butacas**: relación reserva↔butaca. `estado_bloqueo` (TEMPORAL/OCUPADO/LIBERADO), `expira_en` (timestamp), índice único parcial.
- **pagos**: `reserva_id` (FK), `metodo`, `estado`, `comprobante`, `monto`, `pagado_en`.
- **promociones**: `tag`, `titulo`, `descripcion`, `activa_desde`/`activa_hasta`, `activa`.

### Relaciones

- 1:N — usuarios → reservas
- 1:N — peliculas → funciones
- 1:N — salas → butacas, salas → funciones
- 1:N — funciones → reservas, funciones → reserva_butacas
- 1:N — reservas → pagos
- M:N — peliculas ↔ generos (vía `pelicula_generos`)

