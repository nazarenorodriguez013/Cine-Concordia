
CREATE TABLE usuarios (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    apellido        VARCHAR(100) NOT NULL,
    correo          VARCHAR(150) NOT NULL UNIQUE,
    telefono        VARCHAR(30),
    password_hash   VARCHAR(255) NOT NULL,
    rol             VARCHAR(20) NOT NULL DEFAULT 'CLIENTE'
                    CHECK (rol IN ('CLIENTE', 'ADMIN', 'EMPLEADO')),
    creado_en       TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en  TIMESTAMP NOT NULL DEFAULT NOW()
);


CREATE TABLE generos (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE peliculas (
    id              SERIAL PRIMARY KEY,
    titulo          VARCHAR(150) NOT NULL,
    sinopsis        TEXT,
    duracion_min    INTEGER NOT NULL,
    clasificacion   VARCHAR(10),               -- 'ATP', '+13', '+16', ...
    poster_url      VARCHAR(255),
    backdrop_url    VARCHAR(255),               -- imagen de fondo del hero
    trailer_url     VARCHAR(255),
    en_cartelera    BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_estreno   DATE,                       -- alimenta "Próximamente"
    activa          BOOLEAN NOT NULL DEFAULT TRUE, -- soft delete, ver nota abajo
    creado_en       TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE pelicula_generos (
    pelicula_id     INTEGER NOT NULL REFERENCES peliculas(id) ON DELETE CASCADE,
    genero_id       INTEGER NOT NULL REFERENCES generos(id) ON DELETE RESTRICT,
    PRIMARY KEY (pelicula_id, genero_id)
);



CREATE TABLE salas (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    filas           INTEGER NOT NULL,
    columnas        INTEGER NOT NULL,
    capacidad_total INTEGER NOT NULL,
    activa          BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE butacas (
    id              SERIAL PRIMARY KEY,
    sala_id         INTEGER NOT NULL REFERENCES salas(id) ON DELETE CASCADE,
    fila            VARCHAR(5) NOT NULL,
    numero          INTEGER NOT NULL,
    tipo            VARCHAR(20) NOT NULL DEFAULT 'STANDARD'
                    CHECK (tipo IN ('STANDARD', 'VIP', 'ACCESIBLE', 'INHABILITADA')),
    UNIQUE (sala_id, fila, numero)
);


CREATE TABLE funciones (
    id              SERIAL PRIMARY KEY,
    pelicula_id     INTEGER NOT NULL REFERENCES peliculas(id) ON DELETE RESTRICT,
    sala_id         INTEGER NOT NULL REFERENCES salas(id) ON DELETE RESTRICT,
    fecha_hora      TIMESTAMP NOT NULL,
    formato         VARCHAR(10) NOT NULL DEFAULT '2D'
                    CHECK (formato IN ('2D', '3D', 'ATMOS')),
    idioma          VARCHAR(5) NOT NULL DEFAULT 'DOB'
                    CHECK (idioma IN ('DOB', 'SUB')),
    precio_base     NUMERIC(10, 2) NOT NULL,
    cancelada       BOOLEAN NOT NULL DEFAULT FALSE
);


CREATE TABLE tipos_entrada (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(40) NOT NULL UNIQUE,   -- 'General', 'Reducida', 'Estudiante'
    ajuste_precio   NUMERIC(6, 2) NOT NULL DEFAULT 0, -- descuento/recargo sobre precio_base
    activo          BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE reservas (
    id              SERIAL PRIMARY KEY,
    usuario_id      INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
    funcion_id      INTEGER NOT NULL REFERENCES funciones(id) ON DELETE RESTRICT,
    invitado_nombre   VARCHAR(150),
    invitado_correo   VARCHAR(150),
    invitado_telefono VARCHAR(30),
    total           NUMERIC(10, 2) NOT NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                    CHECK (estado IN ('PENDIENTE', 'PAGADA', 'CANCELADA', 'EXPIRADA')),
    codigo_qr       VARCHAR(255) UNIQUE,
    creado_en       TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en  TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_reserva_contacto
        CHECK (usuario_id IS NOT NULL OR invitado_correo IS NOT NULL)
);


CREATE TABLE reserva_butacas (
    id              SERIAL PRIMARY KEY,
    reserva_id      INTEGER NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
    funcion_id      INTEGER NOT NULL REFERENCES funciones(id) ON DELETE CASCADE,
    butaca_id       INTEGER NOT NULL REFERENCES butacas(id) ON DELETE RESTRICT,
    tipo_entrada_id INTEGER NOT NULL REFERENCES tipos_entrada(id) ON DELETE RESTRICT,
    precio_unitario NUMERIC(10, 2) NOT NULL,
    estado_bloqueo  VARCHAR(20) NOT NULL DEFAULT 'TEMPORAL'
                    CHECK (estado_bloqueo IN ('TEMPORAL', 'OCUPADO', 'LIBERADO')),
    expira_en       TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '10 minutes'),
    UNIQUE (butaca_id, reserva_id)
);


CREATE UNIQUE INDEX uq_butaca_funcion_activa
    ON reserva_butacas (funcion_id, butaca_id)
    WHERE estado_bloqueo IN ('TEMPORAL', 'OCUPADO');

CREATE INDEX idx_reserva_butacas_butaca ON reserva_butacas(butaca_id);
CREATE INDEX idx_reserva_butacas_expira ON reserva_butacas(expira_en);


CREATE TABLE pagos (
    id              SERIAL PRIMARY KEY,
    reserva_id      INTEGER NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
    metodo          VARCHAR(30) NOT NULL,        -- 'TARJETA', 'MERCADO_PAGO', ...
    estado          VARCHAR(20) NOT NULL DEFAULT 'APROBADO'
                    CHECK (estado IN ('APROBADO', 'RECHAZADO', 'REEMBOLSADO')),
    comprobante     VARCHAR(255),
    monto           NUMERIC(10, 2) NOT NULL,
    pagado_en       TIMESTAMP NOT NULL DEFAULT NOW()
);


CREATE TABLE promociones (
    id              SERIAL PRIMARY KEY,
    tag             VARCHAR(60) NOT NULL,        -- 'Todos los miércoles'
    titulo          VARCHAR(100) NOT NULL,       -- 'Miércoles 2x1'
    descripcion     TEXT NOT NULL,
    activa_desde    DATE,
    activa_hasta    DATE,
    activa          BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE INDEX idx_peliculas_en_cartelera ON peliculas(en_cartelera) WHERE en_cartelera;
CREATE INDEX idx_pelicula_generos_genero ON pelicula_generos(genero_id);
CREATE INDEX idx_funciones_pelicula ON funciones(pelicula_id);
CREATE INDEX idx_funciones_sala ON funciones(sala_id);
CREATE INDEX idx_funciones_fecha ON funciones(fecha_hora);
CREATE INDEX idx_reservas_usuario ON reservas(usuario_id);
CREATE INDEX idx_reservas_funcion ON reservas(funcion_id);
CREATE INDEX idx_butacas_sala ON butacas(sala_id);
CREATE INDEX idx_promociones_activa ON promociones(activa) WHERE activa;


CREATE OR REPLACE FUNCTION set_actualizado_en()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usuarios_actualizado_en
    BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

CREATE TRIGGER trg_peliculas_actualizado_en
    BEFORE UPDATE ON peliculas
    FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

CREATE TRIGGER trg_reservas_actualizado_en
    BEFORE UPDATE ON reservas
    FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();
