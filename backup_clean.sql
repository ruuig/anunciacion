--
-- PostgreSQL database dump
--

-- Dumped from database version 16rc1
-- Dumped by pg_dump version 16rc1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: actualizar_cantidad_estudiantes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.actualizar_cantidad_estudiantes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE secciones
    SET cantidad_estudiantes = cantidad_estudiantes + 1
    WHERE id = NEW.seccion_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE secciones
    SET cantidad_estudiantes = cantidad_estudiantes - 1
    WHERE id = OLD.seccion_id;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.seccion_id != NEW.seccion_id THEN
      UPDATE secciones
      SET cantidad_estudiantes = cantidad_estudiantes - 1
      WHERE id = OLD.seccion_id;
      UPDATE secciones
      SET cantidad_estudiantes = cantidad_estudiantes + 1
      WHERE id = NEW.seccion_id;
    END IF;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: actualizar_estado_cuenta(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.actualizar_estado_cuenta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  estudiante_id_pago INTEGER;
BEGIN
  estudiante_id_pago := NEW.estudiante_id;

  UPDATE estado_cuenta_estudiante
  SET total_pagado = (
    SELECT COALESCE(SUM(monto), 0)
    FROM pagos
    WHERE estudiante_id = estudiante_id_pago AND estado = 'verificado'
  ),
  saldo = (
    SELECT COALESCE(SUM(monto), 0) - (
      SELECT COALESCE(SUM(monto), 0)
      FROM pagos
      WHERE estudiante_id = estudiante_id_pago AND estado = 'verificado'
    )
    FROM pagos
    WHERE estudiante_id = estudiante_id_pago
  ),
  fecha_ultimo_pago = (
    SELECT MAX(fecha_pago)
    FROM pagos
    WHERE estudiante_id = estudiante_id_pago AND estado = 'verificado'
  ),
  estado_pago = CASE
    WHEN (
      SELECT COALESCE(SUM(monto), 0) - (
        SELECT COALESCE(SUM(monto), 0)
        FROM pagos
        WHERE estudiante_id = estudiante_id_pago AND estado = 'verificado'
      )
      FROM pagos
      WHERE estudiante_id = estudiante_id_pago
    ) > 0 THEN 'pendiente'
    ELSE 'al_dia'
  END,
  fecha_actualizacion = CURRENT_TIMESTAMP
  WHERE estudiante_id = estudiante_id_pago;

  RETURN NEW;
END;
$$;


--
-- Name: actualizar_nota_final_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.actualizar_nota_final_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_materia_id INTEGER;
    v_grado_id INTEGER;
    v_periodo VARCHAR;
    v_ano_academico INTEGER;
    v_docente_id INTEGER;
    v_nota_calculada DECIMAL(5,2);
BEGIN
    -- Obtener datos de la actividad
    SELECT materia_id, grado_id, periodo, ano_academico, docente_id
    INTO v_materia_id, v_grado_id, v_periodo, v_ano_academico, v_docente_id
    FROM actividades
    WHERE id = NEW.actividad_id;
    
    -- Calcular la nota desde actividades
    v_nota_calculada := calcular_nota_desde_actividades(
        NEW.estudiante_id,
        v_materia_id,
        v_grado_id,
        v_periodo,
        v_ano_academico
    );
    
    -- Insertar o actualizar en calificaciones (solo si NO usa nota manual)
    INSERT INTO calificaciones (
        estudiante_id, materia_id, grado_id, docente_id, periodo, 
        ano_academico, nota_final, usar_nota_manual
    )
    VALUES (
        NEW.estudiante_id, v_materia_id, v_grado_id, v_docente_id, v_periodo,
        v_ano_academico, v_nota_calculada, false
    )
    ON CONFLICT (estudiante_id, materia_id, grado_id, periodo, ano_academico)
    DO UPDATE SET
        nota_final = CASE 
            WHEN calificaciones.usar_nota_manual = false THEN v_nota_calculada
            ELSE calificaciones.nota_final
        END,
        fecha_actualizacion = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$;


--
-- Name: calcular_nota_desde_actividades(integer, integer, integer, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calcular_nota_desde_actividades(p_estudiante_id integer, p_materia_id integer, p_grado_id integer, p_periodo character varying, p_ano_academico integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_nota_calculada DECIMAL(5,2);
BEGIN
    -- Sumar todas las notas de actividades (mÃ¡ximo 100)
    SELECT 
        LEAST(
            COALESCE(SUM(ca.nota), 0),
            100
        )
    INTO v_nota_calculada
    FROM calificaciones_actividad ca
    INNER JOIN actividades a ON ca.actividad_id = a.id
    WHERE ca.estudiante_id = p_estudiante_id
      AND a.materia_id = p_materia_id
      AND a.grado_id = p_grado_id
      AND a.periodo = p_periodo
      AND a.ano_academico = p_ano_academico
      AND a.activo = true;
    
    RETURN ROUND(v_nota_calculada, 2);
END;
$$;


--
-- Name: calcular_porcentaje_calificacion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calcular_porcentaje_calificacion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  puntos_maximos_actividad DECIMAL(5,2);
BEGIN
  SELECT puntos_maximos INTO puntos_maximos_actividad
  FROM actividades
  WHERE id = NEW.actividad_id;

  IF puntos_maximos_actividad IS NOT NULL AND puntos_maximos_actividad > 0 THEN
    NEW.porcentaje_calificacion = (NEW.puntos_obtenidos / puntos_maximos_actividad) * 100;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: generar_numero_recibo(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generar_numero_recibo() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
  nuevo_numero VARCHAR;
  contador INTEGER := 1;
BEGIN
  LOOP
    nuevo_numero := 'REC-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(contador::TEXT, 4, '0');

    IF NOT EXISTS (SELECT 1 FROM pagos WHERE numero_recibo = nuevo_numero) THEN
      RETURN nuevo_numero;
    END IF;

    contador := contador + 1;
  END LOOP;
END;
$$;


--
-- Name: update_asistencia_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_asistencia_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_calificaciones_actividad_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_calificaciones_actividad_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_calificaciones_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_calificaciones_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: actividades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.actividades (
    id integer NOT NULL,
    nombre character varying(200) NOT NULL,
    descripcion text,
    docente_id integer NOT NULL,
    materia_id integer NOT NULL,
    grado_id integer NOT NULL,
    seccion_id integer,
    periodo_id integer,
    tipo character varying(20) NOT NULL,
    puntos_maximos numeric(5,2) NOT NULL,
    ponderacion_porcentaje numeric(5,2),
    fecha_entrega date,
    estado character varying(20) DEFAULT 'pendiente'::character varying,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    periodo character varying(50) NOT NULL,
    ano_academico integer NOT NULL,
    ponderacion numeric(5,2) DEFAULT 100.00 NOT NULL,
    activo boolean DEFAULT true,
    CONSTRAINT actividades_ponderacion_check CHECK ((ponderacion > (0)::numeric))
);


--
-- Name: actividades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.actividades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: actividades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.actividades_id_seq OWNED BY public.actividades.id;


--
-- Name: asistencia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asistencia (
    id integer NOT NULL,
    estudiante_id integer NOT NULL,
    fecha date DEFAULT CURRENT_DATE NOT NULL,
    hora_entrada timestamp without time zone,
    hora_salida timestamp without time zone,
    estado character varying(20) DEFAULT 'presente'::character varying NOT NULL,
    observaciones text,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: asistencia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asistencia_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asistencia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asistencia_id_seq OWNED BY public.asistencia.id;


--
-- Name: asistencias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asistencias (
    id integer NOT NULL,
    estudiante_id integer NOT NULL,
    fecha date NOT NULL,
    hora_entrada integer,
    hora_salida integer,
    estado character varying(20) DEFAULT 'presente'::character varying,
    metodo_entrada character varying(20) DEFAULT 'manual'::character varying,
    metodo_salida character varying(20) DEFAULT 'manual'::character varying,
    autorizado_por integer,
    notas text,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: asistencias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asistencias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asistencias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asistencias_id_seq OWNED BY public.asistencias.id;


--
-- Name: auditoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditoria (
    id bigint NOT NULL,
    usuario_id integer,
    accion character varying(100) NOT NULL,
    tabla_afectada character varying(100) NOT NULL,
    registro_id integer,
    valores_anteriores jsonb,
    valores_nuevos jsonb,
    direccion_ip character varying(45),
    user_agent character varying(500),
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditoria_id_seq OWNED BY public.auditoria.id;


--
-- Name: calificaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calificaciones (
    id integer NOT NULL,
    estudiante_id integer NOT NULL,
    materia_id integer NOT NULL,
    grado_id integer NOT NULL,
    docente_id integer NOT NULL,
    periodo character varying(50) NOT NULL,
    nota_final numeric(5,2) NOT NULL,
    ano_academico integer NOT NULL,
    observaciones text,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    nota_manual numeric(5,2),
    usar_nota_manual boolean DEFAULT false,
    CONSTRAINT calificaciones_nota_check CHECK (((nota_final >= (0)::numeric) AND (nota_final <= (100)::numeric))),
    CONSTRAINT calificaciones_nota_manual_check CHECK (((nota_manual >= (0)::numeric) AND (nota_manual <= (100)::numeric)))
);


--
-- Name: calificaciones_actividad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calificaciones_actividad (
    id integer NOT NULL,
    actividad_id integer NOT NULL,
    estudiante_id integer NOT NULL,
    nota numeric(5,2) NOT NULL,
    observaciones text,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT calificaciones_actividad_nota_check CHECK (((nota >= (0)::numeric) AND (nota <= (100)::numeric)))
);


--
-- Name: calificaciones_actividad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calificaciones_actividad_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calificaciones_actividad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calificaciones_actividad_id_seq OWNED BY public.calificaciones_actividad.id;


--
-- Name: calificaciones_actividades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calificaciones_actividades (
    id integer NOT NULL,
    actividad_id integer NOT NULL,
    estudiante_id integer NOT NULL,
    puntos_obtenidos numeric(5,2),
    porcentaje_calificacion numeric(5,2),
    comentarios text,
    calificado_por integer NOT NULL,
    fecha_calificacion timestamp without time zone,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: calificaciones_actividades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calificaciones_actividades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calificaciones_actividades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calificaciones_actividades_id_seq OWNED BY public.calificaciones_actividades.id;


--
-- Name: calificaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calificaciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calificaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calificaciones_id_seq OWNED BY public.calificaciones.id;


--
-- Name: conceptos_pago; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conceptos_pago (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    monto_por_defecto numeric(10,2),
    tipo character varying(20),
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: conceptos_pago_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conceptos_pago_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conceptos_pago_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conceptos_pago_id_seq OWNED BY public.conceptos_pago.id;


--
-- Name: estado_cuenta_estudiante; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estado_cuenta_estudiante (
    id integer NOT NULL,
    estudiante_id integer NOT NULL,
    total_cargado numeric(10,2) DEFAULT 0,
    total_pagado numeric(10,2) DEFAULT 0,
    saldo numeric(10,2) DEFAULT 0,
    fecha_ultimo_pago date,
    estado_pago character varying(20) DEFAULT 'al_dia'::character varying,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: estado_cuenta_estudiante_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estado_cuenta_estudiante_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estado_cuenta_estudiante_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estado_cuenta_estudiante_id_seq OWNED BY public.estado_cuenta_estudiante.id;


--
-- Name: estudiantes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estudiantes (
    id integer NOT NULL,
    nombre character varying(200) NOT NULL,
    fecha_nacimiento date NOT NULL,
    genero character varying(20),
    direccion character varying(500),
    telefono character varying(20),
    email character varying(150),
    url_avatar character varying(500),
    grado_id integer NOT NULL,
    fecha_inscripcion date NOT NULL,
    estado character varying(20) DEFAULT 'activo'::character varying,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    codigo character varying(20) NOT NULL,
    dpi character varying(20) NOT NULL
);


--
-- Name: COLUMN estudiantes.grado_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.estudiantes.grado_id IS 'ID del grado que incluye la sección (ej: Primero A, Primero B)';


--
-- Name: COLUMN estudiantes.codigo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.estudiantes.codigo IS 'Código único del estudiante asignado por el gobierno (ejemplo: C716KYD)';


--
-- Name: COLUMN estudiantes.dpi; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.estudiantes.dpi IS 'CUI del estudiante - Código Único de Identificación (13 dígitos)';


--
-- Name: estudiantes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estudiantes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estudiantes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estudiantes_id_seq OWNED BY public.estudiantes.id;


--
-- Name: estudiantes_padres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estudiantes_padres (
    id integer NOT NULL,
    estudiante_id integer NOT NULL,
    padre_id integer NOT NULL,
    es_contacto_principal boolean DEFAULT false,
    es_contacto_emergencia boolean DEFAULT false,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: estudiantes_padres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estudiantes_padres_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estudiantes_padres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estudiantes_padres_id_seq OWNED BY public.estudiantes_padres.id;


--
-- Name: grados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grados (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    nivel_educativo_id integer NOT NULL,
    rango_edad character varying(50),
    ano_academico character varying(9) NOT NULL,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: grados_docentes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grados_docentes (
    id integer NOT NULL,
    grado_id integer NOT NULL,
    docente_id integer NOT NULL,
    ano_academico integer NOT NULL,
    activo boolean DEFAULT true,
    fecha_asignacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE grados_docentes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.grados_docentes IS 'Asignación de docentes a grados. Los docentes ya tienen sus materias asignadas en materias_docentes';


--
-- Name: COLUMN grados_docentes.grado_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.grados_docentes.grado_id IS 'Grado al que se asigna el docente';


--
-- Name: COLUMN grados_docentes.docente_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.grados_docentes.docente_id IS 'Docente asignado al grado';


--
-- Name: COLUMN grados_docentes.ano_academico; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.grados_docentes.ano_academico IS 'Año académico de la asignación';


--
-- Name: grados_docentes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grados_docentes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grados_docentes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grados_docentes_id_seq OWNED BY public.grados_docentes.id;


--
-- Name: grados_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grados_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grados_id_seq OWNED BY public.grados.id;


--
-- Name: grados_materias_docentes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grados_materias_docentes (
    id integer NOT NULL,
    grado_id integer NOT NULL,
    materia_id integer NOT NULL,
    docente_id integer NOT NULL,
    ano_academico integer NOT NULL,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: grados_materias_docentes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grados_materias_docentes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grados_materias_docentes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grados_materias_docentes_id_seq OWNED BY public.grados_materias_docentes.id;


--
-- Name: materias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materias (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    codigo character varying(20),
    descripcion text,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: materias_docentes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materias_docentes (
    id integer NOT NULL,
    materia_id integer NOT NULL,
    docente_id integer NOT NULL,
    fecha_asignacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    activo boolean DEFAULT true
);


--
-- Name: materias_docentes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materias_docentes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materias_docentes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materias_docentes_id_seq OWNED BY public.materias_docentes.id;


--
-- Name: materias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materias_id_seq OWNED BY public.materias.id;


--
-- Name: niveles_educativos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.niveles_educativos (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    orden integer NOT NULL,
    color_hex character varying(7),
    activo boolean DEFAULT true
);


--
-- Name: niveles_educativos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.niveles_educativos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: niveles_educativos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.niveles_educativos_id_seq OWNED BY public.niveles_educativos.id;


--
-- Name: padres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.padres (
    id integer NOT NULL,
    dpi character varying(20),
    nombre character varying(200) NOT NULL,
    relacion character varying(50) NOT NULL,
    telefono character varying(20) NOT NULL,
    telefono_secundario character varying(20),
    email character varying(150),
    direccion character varying(500),
    ocupacion character varying(100),
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: padres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.padres_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: padres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.padres_id_seq OWNED BY public.padres.id;


--
-- Name: pagos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pagos (
    id integer NOT NULL,
    estudiante_id integer NOT NULL,
    concepto_id integer,
    monto numeric(10,2) NOT NULL,
    fecha_pago date NOT NULL,
    metodo_pago character varying(20),
    numero_referencia character varying(100),
    numero_recibo character varying(100),
    estado character varying(20) DEFAULT 'pendiente'::character varying,
    comentarios text,
    registrado_por integer,
    verificado_por integer,
    fecha_verificacion timestamp without time zone,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    mes character varying(50),
    referencia character varying(255),
    comprobante_url character varying(500),
    notas text,
    creado_por integer,
    actualizado_por integer
);


--
-- Name: TABLE pagos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pagos IS 'Registro de pagos de mensualidades y otros conceptos';


--
-- Name: COLUMN pagos.estudiante_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos.estudiante_id IS 'ID del estudiante que realizó el pago';


--
-- Name: COLUMN pagos.monto; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos.monto IS 'Monto del pago en quetzales';


--
-- Name: COLUMN pagos.metodo_pago; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos.metodo_pago IS 'Método utilizado para el pago';


--
-- Name: COLUMN pagos.estado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos.estado IS 'Estado del pago: activo o eliminado (soft delete)';


--
-- Name: COLUMN pagos.mes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos.mes IS 'Mes o periodo al que corresponde el pago';


--
-- Name: COLUMN pagos.referencia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos.referencia IS 'Referencia del pago (boleta, banco, etc.)';


--
-- Name: pagos_bus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pagos_bus (
    id integer NOT NULL,
    estudiante_id integer NOT NULL,
    monto numeric(10,2) NOT NULL,
    mes character varying(50) NOT NULL,
    fecha_pago date DEFAULT CURRENT_DATE NOT NULL,
    metodo_pago character varying(50),
    referencia character varying(255),
    comprobante_url character varying(500),
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    notas text,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    creado_por integer,
    actualizado_por integer
);


--
-- Name: TABLE pagos_bus; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pagos_bus IS 'Registro de pagos de servicio de bus';


--
-- Name: COLUMN pagos_bus.estudiante_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos_bus.estudiante_id IS 'ID del estudiante que realizÃ³ el pago';


--
-- Name: COLUMN pagos_bus.monto; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos_bus.monto IS 'Monto del pago en quetzales';


--
-- Name: COLUMN pagos_bus.mes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos_bus.mes IS 'Mes o periodo al que corresponde el pago';


--
-- Name: COLUMN pagos_bus.estado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagos_bus.estado IS 'Estado del pago: activo o eliminado (soft delete)';


--
-- Name: pagos_bus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pagos_bus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pagos_bus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pagos_bus_id_seq OWNED BY public.pagos_bus.id;


--
-- Name: pagos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pagos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pagos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pagos_id_seq OWNED BY public.pagos.id;


--
-- Name: periodos_academicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.periodos_academicos (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    ano_academico character varying(9) NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date NOT NULL,
    orden integer NOT NULL,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: periodos_academicos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.periodos_academicos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: periodos_academicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.periodos_academicos_id_seq OWNED BY public.periodos_academicos.id;


--
-- Name: permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permisos (
    id integer NOT NULL,
    codigo character varying(100) NOT NULL,
    modulo character varying(50) NOT NULL,
    descripcion text,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: permisos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permisos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permisos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permisos_id_seq OWNED BY public.permisos.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text,
    nivel integer NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: roles_permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles_permisos (
    id integer NOT NULL,
    rol_id integer NOT NULL,
    permiso_id integer NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: roles_permisos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_permisos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_permisos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_permisos_id_seq OWNED BY public.roles_permisos.id;


--
-- Name: secciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.secciones (
    id integer NOT NULL,
    grado_id integer NOT NULL,
    nombre character varying(10) NOT NULL,
    capacidad integer,
    cantidad_estudiantes integer DEFAULT 0,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: secciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.secciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: secciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.secciones_id_seq OWNED BY public.secciones.id;


--
-- Name: servicio_bus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servicio_bus (
    id integer NOT NULL,
    estudiante_id integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    monto_mensual numeric(10,2) DEFAULT 200.00 NOT NULL,
    ruta character varying(255),
    parada character varying(255),
    notas text,
    fecha_inicio date DEFAULT CURRENT_DATE NOT NULL,
    fecha_fin date,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    creado_por integer,
    actualizado_por integer
);


--
-- Name: TABLE servicio_bus; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.servicio_bus IS 'Registro de estudiantes con servicio de bus activo';


--
-- Name: COLUMN servicio_bus.estudiante_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.servicio_bus.estudiante_id IS 'ID del estudiante';


--
-- Name: COLUMN servicio_bus.activo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.servicio_bus.activo IS 'Si el servicio estÃ¡ activo o no';


--
-- Name: COLUMN servicio_bus.monto_mensual; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.servicio_bus.monto_mensual IS 'Monto mensual del servicio de bus';


--
-- Name: servicio_bus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.servicio_bus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: servicio_bus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.servicio_bus_id_seq OWNED BY public.servicio_bus.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(200) NOT NULL,
    username character varying(50) NOT NULL,
    password text NOT NULL,
    telefono character varying(20),
    rol_id integer NOT NULL,
    estado character varying(20) DEFAULT 'activo'::character varying,
    url_avatar character varying(500),
    ultimo_acceso timestamp without time zone,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: actividades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actividades ALTER COLUMN id SET DEFAULT nextval('public.actividades_id_seq'::regclass);


--
-- Name: asistencia id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencia ALTER COLUMN id SET DEFAULT nextval('public.asistencia_id_seq'::regclass);


--
-- Name: asistencias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencias ALTER COLUMN id SET DEFAULT nextval('public.asistencias_id_seq'::regclass);


--
-- Name: auditoria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria ALTER COLUMN id SET DEFAULT nextval('public.auditoria_id_seq'::regclass);


--
-- Name: calificaciones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones ALTER COLUMN id SET DEFAULT nextval('public.calificaciones_id_seq'::regclass);


--
-- Name: calificaciones_actividad id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividad ALTER COLUMN id SET DEFAULT nextval('public.calificaciones_actividad_id_seq'::regclass);


--
-- Name: calificaciones_actividades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividades ALTER COLUMN id SET DEFAULT nextval('public.calificaciones_actividades_id_seq'::regclass);


--
-- Name: conceptos_pago id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_pago ALTER COLUMN id SET DEFAULT nextval('public.conceptos_pago_id_seq'::regclass);


--
-- Name: estado_cuenta_estudiante id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estado_cuenta_estudiante ALTER COLUMN id SET DEFAULT nextval('public.estado_cuenta_estudiante_id_seq'::regclass);


--
-- Name: estudiantes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes ALTER COLUMN id SET DEFAULT nextval('public.estudiantes_id_seq'::regclass);


--
-- Name: estudiantes_padres id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes_padres ALTER COLUMN id SET DEFAULT nextval('public.estudiantes_padres_id_seq'::regclass);


--
-- Name: grados id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados ALTER COLUMN id SET DEFAULT nextval('public.grados_id_seq'::regclass);


--
-- Name: grados_docentes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_docentes ALTER COLUMN id SET DEFAULT nextval('public.grados_docentes_id_seq'::regclass);


--
-- Name: grados_materias_docentes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_materias_docentes ALTER COLUMN id SET DEFAULT nextval('public.grados_materias_docentes_id_seq'::regclass);


--
-- Name: materias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materias ALTER COLUMN id SET DEFAULT nextval('public.materias_id_seq'::regclass);


--
-- Name: materias_docentes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materias_docentes ALTER COLUMN id SET DEFAULT nextval('public.materias_docentes_id_seq'::regclass);


--
-- Name: niveles_educativos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.niveles_educativos ALTER COLUMN id SET DEFAULT nextval('public.niveles_educativos_id_seq'::regclass);


--
-- Name: padres id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.padres ALTER COLUMN id SET DEFAULT nextval('public.padres_id_seq'::regclass);


--
-- Name: pagos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos ALTER COLUMN id SET DEFAULT nextval('public.pagos_id_seq'::regclass);


--
-- Name: pagos_bus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos_bus ALTER COLUMN id SET DEFAULT nextval('public.pagos_bus_id_seq'::regclass);


--
-- Name: periodos_academicos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_academicos ALTER COLUMN id SET DEFAULT nextval('public.periodos_academicos_id_seq'::regclass);


--
-- Name: permisos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos ALTER COLUMN id SET DEFAULT nextval('public.permisos_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: roles_permisos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles_permisos ALTER COLUMN id SET DEFAULT nextval('public.roles_permisos_id_seq'::regclass);


--
-- Name: secciones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secciones ALTER COLUMN id SET DEFAULT nextval('public.secciones_id_seq'::regclass);


--
-- Name: servicio_bus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_bus ALTER COLUMN id SET DEFAULT nextval('public.servicio_bus_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Data for Name: actividades; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.actividades (id, nombre, descripcion, docente_id, materia_id, grado_id, seccion_id, periodo_id, tipo, puntos_maximos, ponderacion_porcentaje, fecha_entrega, estado, fecha_creacion, fecha_actualizacion, periodo, ano_academico, ponderacion, activo) FROM stdin;
5	23	q2|	5	8	2	\N	\N	Tarea	12.00	\N	2025-11-06	pendiente	2025-11-05 21:15:59.062186	2025-11-05 21:15:59.062186	1	2025	12.00	t
6	werwer	wer23	5	8	2	\N	\N	Tarea	20.00	\N	2025-11-06	pendiente	2025-11-05 21:17:26.367973	2025-11-05 21:17:26.367973	1	2025	20.00	t
7	asd	asdasd	5	8	2	\N	\N	Tarea	1.00	\N	2025-11-06	pendiente	2025-11-05 22:51:05.387616	2025-11-05 22:51:05.387616	1	2025	1.00	t
8	12	123	5	8	2	\N	\N	Tarea	15.00	\N	2025-11-07	pendiente	2025-11-06 19:13:07.454091	2025-11-06 19:13:07.454091	1	2025	15.00	t
9	123	123	5	8	2	\N	\N	Tarea	15.00	\N	2025-11-07	pendiente	2025-11-06 19:30:07.969579	2025-11-06 19:30:07.969579	1	2025	15.00	t
10	solo para probar	123	5	8	2	\N	\N	Tarea	20.00	\N	2025-11-07	pendiente	2025-11-06 23:29:40.130028	2025-11-06 23:29:40.130028	1	2025	20.00	t
\.


--
-- Data for Name: asistencia; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.asistencia (id, estudiante_id, fecha, hora_entrada, hora_salida, estado, observaciones, fecha_creacion, fecha_actualizacion) FROM stdin;
1	8	2025-11-07	2025-11-07 16:32:34.008258	\N	presente	\N	2025-11-07 03:17:30.003294	2025-11-07 16:32:34.008258
7	8	2025-11-13	2025-11-12 21:49:11.109736	2025-11-12 21:49:17.383985	presente	\N	2025-11-12 21:48:35.381656	2025-11-12 21:49:17.383985
\.


--
-- Data for Name: asistencias; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.asistencias (id, estudiante_id, fecha, hora_entrada, hora_salida, estado, metodo_entrada, metodo_salida, autorizado_por, notas, fecha_creacion, fecha_actualizacion) FROM stdin;
\.


--
-- Data for Name: auditoria; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auditoria (id, usuario_id, accion, tabla_afectada, registro_id, valores_anteriores, valores_nuevos, direccion_ip, user_agent, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: calificaciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.calificaciones (id, estudiante_id, materia_id, grado_id, docente_id, periodo, nota_final, ano_academico, observaciones, fecha_registro, fecha_actualizacion, nota_manual, usar_nota_manual) FROM stdin;
1	8	5	2	5	1	0.00	2025	\N	2025-11-05 19:55:15.678884	2025-11-13 19:31:22.498175	76.00	f
2	8	8	2	5	1	64.00	2025	\N	2025-11-05 20:44:29.819007	2025-11-13 19:31:22.498175	97.00	f
\.


--
-- Data for Name: calificaciones_actividad; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.calificaciones_actividad (id, actividad_id, estudiante_id, nota, observaciones, fecha_registro, fecha_actualizacion) FROM stdin;
1	9	8	15.00	\N	2025-11-06 19:56:59.756158	2025-11-06 20:00:02.720516
3	8	8	12.00	\N	2025-11-06 20:00:08.966721	2025-11-06 20:00:08.966721
4	6	8	16.00	\N	2025-11-06 20:06:00.945506	2025-11-06 20:06:16.024637
6	7	8	1.00	\N	2025-11-06 22:34:49.841246	2025-11-06 22:34:49.841246
7	10	8	20.00	\N	2025-11-06 23:29:54.419862	2025-11-06 23:29:54.419862
\.


--
-- Data for Name: calificaciones_actividades; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.calificaciones_actividades (id, actividad_id, estudiante_id, puntos_obtenidos, porcentaje_calificacion, comentarios, calificado_por, fecha_calificacion, fecha_creacion, fecha_actualizacion) FROM stdin;
\.


--
-- Data for Name: conceptos_pago; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conceptos_pago (id, nombre, descripcion, monto_por_defecto, tipo, activo, fecha_creacion) FROM stdin;
1	Colegiatura Mensual	Pago mensual por servicios educativos	500.00	mensual	t	2025-11-01 17:09:04.768412
2	Inscripción Anual	Pago de inscripción al inicio del año	200.00	anual	t	2025-11-01 17:09:04.768412
3	Materiales Escolares	Materiales y útiles escolares	100.00	anual	t	2025-11-01 17:09:04.768412
4	Eventos Especiales	Actividades extracurriculares	\N	opcional	t	2025-11-01 17:09:04.768412
5	Seguro Estudiantil	Seguro médico estudiantil	50.00	anual	t	2025-11-01 17:09:04.768412
\.


--
-- Data for Name: estado_cuenta_estudiante; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.estado_cuenta_estudiante (id, estudiante_id, total_cargado, total_pagado, saldo, fecha_ultimo_pago, estado_pago, fecha_actualizacion) FROM stdin;
\.


--
-- Data for Name: estudiantes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.estudiantes (id, nombre, fecha_nacimiento, genero, direccion, telefono, email, url_avatar, grado_id, fecha_inscripcion, estado, fecha_creacion, fecha_actualizacion, codigo, dpi) FROM stdin;
8	Rudy Eleazar Oloroso Gutiérrez	2010-01-14	masculino	\N	\N	\N	\N	2	2025-11-02	activo	2025-11-02 12:46:41.387926	2025-11-13 01:43:31.766872	A123BCD	1123872782003
\.


--
-- Data for Name: estudiantes_padres; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.estudiantes_padres (id, estudiante_id, padre_id, es_contacto_principal, es_contacto_emergencia, fecha_creacion) FROM stdin;
1	8	1	f	f	2025-11-02 14:26:05.941539
\.


--
-- Data for Name: grados; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.grados (id, nombre, nivel_educativo_id, rango_edad, ano_academico, activo, fecha_creacion, fecha_actualizacion) FROM stdin;
3	Segundo A	2	10-12	2024-2025	t	2025-11-02 12:48:02.434826	2025-11-02 12:48:02.434826
4	Primero B	1	7	2025	t	2025-11-02 15:50:18.088689	2025-11-02 15:50:18.088689
2	Primero A	1	7-10	2024-2025	t	2025-11-02 09:39:31.781212	2025-11-02 19:59:07.824494
\.


--
-- Data for Name: grados_docentes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.grados_docentes (id, grado_id, docente_id, ano_academico, activo, fecha_asignacion) FROM stdin;
2	2	8	2025	t	2025-11-13 18:46:24.440383
1	2	5	2025	t	2025-11-02 19:59:07.883092
\.


--
-- Data for Name: grados_materias_docentes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.grados_materias_docentes (id, grado_id, materia_id, docente_id, ano_academico, activo, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: materias; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.materias (id, nombre, codigo, descripcion, activo, fecha_creacion) FROM stdin;
5	Inglés	ING	Idioma inglés	t	2025-11-01 17:09:04.768412
8	Computación	COMP	Tecnología e informática	t	2025-11-01 17:09:04.768412
3	Ciencias Naturales	CN	Biología, Física y Química	t	2025-11-01 17:09:04.768412
2	Español	ESP	Lenguaje y comunicación	t	2025-11-01 17:09:04.768412
4	Estudios Sociales	ES	Historia, Geografía y Civismo	t	2025-11-01 17:09:04.768412
7	Expresión Artística	ART	Expresión artística	t	2025-11-01 17:09:04.768412
1	Matemáticas	MAT	Matemáticas básicas y avanzadas	t	2025-11-01 17:09:04.768412
6	Educación Física	EF	Actividad física y deporte	t	2025-11-01 17:09:04.768412
\.


--
-- Data for Name: materias_docentes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.materias_docentes (id, materia_id, docente_id, fecha_asignacion, activo) FROM stdin;
1	5	5	2025-11-02 19:50:50.544938	t
2	8	5	2025-11-02 19:50:56.035336	t
4	3	8	2025-11-13 18:12:24.789556	t
5	2	8	2025-11-13 18:12:28.777518	t
6	4	8	2025-11-13 18:12:32.239547	t
7	7	8	2025-11-13 18:12:35.337147	t
8	1	8	2025-11-13 18:12:46.466879	t
\.


--
-- Data for Name: niveles_educativos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.niveles_educativos (id, nombre, orden, color_hex, activo) FROM stdin;
1	Preprimaria	1	#EC4899	t
2	Primaria	2	#3B82F6	t
3	Secundaria	3	#10B981	t
\.


--
-- Data for Name: padres; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.padres (id, dpi, nombre, relacion, telefono, telefono_secundario, email, direccion, ocupacion, fecha_creacion, fecha_actualizacion) FROM stdin;
1	1238283232994	Hellen Liliana Gutiérrez Carrera	Madre	+50248268089	\N	\N	\N	\N	2025-11-02 14:26:05.906338	2025-11-02 14:26:12.336616
2	\N	Juan Randy Loper Perez	Padre	+50242489635	\N	\N	\N	\N	2025-11-02 14:36:39.311774	2025-11-02 14:36:39.311774
\.


--
-- Data for Name: pagos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pagos (id, estudiante_id, concepto_id, monto, fecha_pago, metodo_pago, numero_referencia, numero_recibo, estado, comentarios, registrado_por, verificado_por, fecha_verificacion, fecha_creacion, fecha_actualizacion, mes, referencia, comprobante_url, notas, creado_por, actualizado_por) FROM stdin;
26	8	1	270.00	2025-11-14	Transferencia	\N	\N	activo	\N	\N	\N	\N	2025-11-13 22:37:39.665578	2025-11-13 22:37:39.665578	Enero 2025	2803423	\N	\N	\N	\N
25	8	1	1.00	2025-11-13	Transferencia	\N	\N	eliminado	\N	\N	\N	\N	2025-11-12 21:57:32.4261	2025-11-13 23:28:54.511678	Octubre 2025	Trans: 32788854	\N	\N	\N	\N
27	8	1	100.00	2025-11-14	Efectivo	\N	\N	eliminado	\N	\N	\N	\N	2025-11-14 00:13:02.49348	2025-11-14 00:13:29.607184	Inscripción	\N	\N	primera parte de pago	\N	\N
\.


--
-- Data for Name: pagos_bus; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pagos_bus (id, estudiante_id, monto, mes, fecha_pago, metodo_pago, referencia, comprobante_url, estado, notas, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por) FROM stdin;
1	8	200.00	Enero	2025-11-14	Efectivo	123	\N	activo	\N	2025-11-14 00:17:20.265942	2025-11-14 00:17:20.265942	\N	\N
2	8	200.00	Enero	2025-11-14	Efectivo	2322	\N	activo	\N	2025-11-14 00:25:26.497469	2025-11-14 00:25:26.497469	\N	\N
\.


--
-- Data for Name: periodos_academicos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.periodos_academicos (id, nombre, ano_academico, fecha_inicio, fecha_fin, orden, activo, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: permisos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.permisos (id, codigo, modulo, descripcion, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id, nombre, descripcion, nivel, fecha_creacion) FROM stdin;
1	Administrador General	Acceso total a todo	1	2025-11-01 17:09:04.768412
2	Docente	Acceso a clases y estudiantes	2	2025-11-01 17:09:04.768412
3	Director/Secretaria	Acceso administrativo	3	2025-11-01 17:09:04.768412
4	Padre	Acceso a hijos	4	2025-11-01 17:09:04.768412
\.


--
-- Data for Name: roles_permisos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles_permisos (id, rol_id, permiso_id, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: secciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.secciones (id, grado_id, nombre, capacidad, cantidad_estudiantes, activo, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: servicio_bus; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.servicio_bus (id, estudiante_id, activo, monto_mensual, ruta, parada, notas, fecha_inicio, fecha_fin, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por) FROM stdin;
1	8	t	200.00	\N	\N	\N	2025-11-12	2025-11-13	2025-11-12 23:48:22.17115	2025-11-13 01:43:31.808852	\N	\N
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuarios (id, nombre, username, password, telefono, rol_id, estado, url_avatar, ultimo_acceso, fecha_creacion, fecha_actualizacion) FROM stdin;
2	Docente Ejemplo	docente1	docente123	50223456789	2	activo	\N	\N	2025-11-01 17:09:04.768412	2025-11-01 17:09:04.768412
3	Directora Ejemplo	directora1	directora123	50234567890	3	activo	\N	\N	2025-11-01 17:09:04.768412	2025-11-01 17:09:04.768412
4	Padre Ejemplo	padre1	padre123	50245678901	4	activo	\N	\N	2025-11-01 17:09:04.768412	2025-11-01 17:09:04.768412
7	Juan Randy Loper Perez	juan2	changeme1	+50242489635	4	activo	\N	\N	2025-11-02 14:36:39.320425	2025-11-02 14:36:39.320425
5	Rudy Oloroso	rudy	rudy123	\N	2	activo	\N	2025-11-12 21:34:42.69991	2025-11-01 22:47:11.236958	2025-11-12 21:34:42.69991
1	Administrador del Sistema	admin	admin123	50212345678	1	activo	\N	2025-11-14 00:43:46.316415	2025-11-01 17:09:04.768412	2025-11-14 00:43:46.316415
8	Norilda Pérez Canán	norilda	norilda123	\N	2	activo	\N	\N	2025-11-13 18:12:01.145189	2025-11-13 18:12:01.145189
\.


--
-- Name: actividades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.actividades_id_seq', 10, true);


--
-- Name: asistencia_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.asistencia_id_seq', 12, true);


--
-- Name: asistencias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.asistencias_id_seq', 1, false);


--
-- Name: auditoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auditoria_id_seq', 1, false);


--
-- Name: calificaciones_actividad_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.calificaciones_actividad_id_seq', 7, true);


--
-- Name: calificaciones_actividades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.calificaciones_actividades_id_seq', 1, false);


--
-- Name: calificaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.calificaciones_id_seq', 12, true);


--
-- Name: conceptos_pago_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conceptos_pago_id_seq', 5, true);


--
-- Name: estado_cuenta_estudiante_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.estado_cuenta_estudiante_id_seq', 1, false);


--
-- Name: estudiantes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.estudiantes_id_seq', 9, true);


--
-- Name: estudiantes_padres_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.estudiantes_padres_id_seq', 2, true);


--
-- Name: grados_docentes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.grados_docentes_id_seq', 7, true);


--
-- Name: grados_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.grados_id_seq', 5, true);


--
-- Name: grados_materias_docentes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.grados_materias_docentes_id_seq', 1, false);


--
-- Name: materias_docentes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.materias_docentes_id_seq', 8, true);


--
-- Name: materias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.materias_id_seq', 8, true);


--
-- Name: niveles_educativos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.niveles_educativos_id_seq', 3, true);


--
-- Name: padres_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.padres_id_seq', 2, true);


--
-- Name: pagos_bus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pagos_bus_id_seq', 2, true);


--
-- Name: pagos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pagos_id_seq', 27, true);


--
-- Name: periodos_academicos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.periodos_academicos_id_seq', 1, false);


--
-- Name: permisos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.permisos_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_id_seq', 4, true);


--
-- Name: roles_permisos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_permisos_id_seq', 1, false);


--
-- Name: secciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.secciones_id_seq', 1, false);


--
-- Name: servicio_bus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.servicio_bus_id_seq', 3, true);


--
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 8, true);


--
-- Name: actividades actividades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actividades
    ADD CONSTRAINT actividades_pkey PRIMARY KEY (id);


--
-- Name: asistencia asistencia_estudiante_id_fecha_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencia
    ADD CONSTRAINT asistencia_estudiante_id_fecha_key UNIQUE (estudiante_id, fecha);


--
-- Name: asistencia asistencia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencia
    ADD CONSTRAINT asistencia_pkey PRIMARY KEY (id);


--
-- Name: asistencias asistencias_estudiante_id_fecha_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencias
    ADD CONSTRAINT asistencias_estudiante_id_fecha_key UNIQUE (estudiante_id, fecha);


--
-- Name: asistencias asistencias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencias
    ADD CONSTRAINT asistencias_pkey PRIMARY KEY (id);


--
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- Name: calificaciones_actividad calificaciones_actividad_actividad_id_estudiante_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividad
    ADD CONSTRAINT calificaciones_actividad_actividad_id_estudiante_id_key UNIQUE (actividad_id, estudiante_id);


--
-- Name: calificaciones_actividad calificaciones_actividad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividad
    ADD CONSTRAINT calificaciones_actividad_pkey PRIMARY KEY (id);


--
-- Name: calificaciones_actividades calificaciones_actividades_actividad_id_estudiante_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividades
    ADD CONSTRAINT calificaciones_actividades_actividad_id_estudiante_id_key UNIQUE (actividad_id, estudiante_id);


--
-- Name: calificaciones_actividades calificaciones_actividades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividades
    ADD CONSTRAINT calificaciones_actividades_pkey PRIMARY KEY (id);


--
-- Name: calificaciones calificaciones_estudiante_id_materia_id_grado_id_periodo_an_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones
    ADD CONSTRAINT calificaciones_estudiante_id_materia_id_grado_id_periodo_an_key UNIQUE (estudiante_id, materia_id, grado_id, periodo, ano_academico);


--
-- Name: calificaciones calificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones
    ADD CONSTRAINT calificaciones_pkey PRIMARY KEY (id);


--
-- Name: conceptos_pago conceptos_pago_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_pago
    ADD CONSTRAINT conceptos_pago_nombre_key UNIQUE (nombre);


--
-- Name: conceptos_pago conceptos_pago_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_pago
    ADD CONSTRAINT conceptos_pago_pkey PRIMARY KEY (id);


--
-- Name: estado_cuenta_estudiante estado_cuenta_estudiante_estudiante_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estado_cuenta_estudiante
    ADD CONSTRAINT estado_cuenta_estudiante_estudiante_id_key UNIQUE (estudiante_id);


--
-- Name: estado_cuenta_estudiante estado_cuenta_estudiante_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estado_cuenta_estudiante
    ADD CONSTRAINT estado_cuenta_estudiante_pkey PRIMARY KEY (id);


--
-- Name: estudiantes estudiantes_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes
    ADD CONSTRAINT estudiantes_codigo_key UNIQUE (codigo);


--
-- Name: estudiantes estudiantes_dpi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes
    ADD CONSTRAINT estudiantes_dpi_key UNIQUE (dpi);


--
-- Name: estudiantes_padres estudiantes_padres_estudiante_id_padre_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes_padres
    ADD CONSTRAINT estudiantes_padres_estudiante_id_padre_id_key UNIQUE (estudiante_id, padre_id);


--
-- Name: estudiantes_padres estudiantes_padres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes_padres
    ADD CONSTRAINT estudiantes_padres_pkey PRIMARY KEY (id);


--
-- Name: estudiantes estudiantes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes
    ADD CONSTRAINT estudiantes_pkey PRIMARY KEY (id);


--
-- Name: grados_docentes grados_docentes_grado_id_docente_id_ano_academico_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_docentes
    ADD CONSTRAINT grados_docentes_grado_id_docente_id_ano_academico_key UNIQUE (grado_id, docente_id, ano_academico);


--
-- Name: grados_docentes grados_docentes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_docentes
    ADD CONSTRAINT grados_docentes_pkey PRIMARY KEY (id);


--
-- Name: grados_materias_docentes grados_materias_docentes_grado_id_materia_id_ano_academico_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_materias_docentes
    ADD CONSTRAINT grados_materias_docentes_grado_id_materia_id_ano_academico_key UNIQUE (grado_id, materia_id, ano_academico);


--
-- Name: grados_materias_docentes grados_materias_docentes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_materias_docentes
    ADD CONSTRAINT grados_materias_docentes_pkey PRIMARY KEY (id);


--
-- Name: grados grados_nombre_ano_academico_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados
    ADD CONSTRAINT grados_nombre_ano_academico_key UNIQUE (nombre, ano_academico);


--
-- Name: grados grados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados
    ADD CONSTRAINT grados_pkey PRIMARY KEY (id);


--
-- Name: materias materias_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materias
    ADD CONSTRAINT materias_codigo_key UNIQUE (codigo);


--
-- Name: materias_docentes materias_docentes_materia_id_docente_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materias_docentes
    ADD CONSTRAINT materias_docentes_materia_id_docente_id_key UNIQUE (materia_id, docente_id);


--
-- Name: materias_docentes materias_docentes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materias_docentes
    ADD CONSTRAINT materias_docentes_pkey PRIMARY KEY (id);


--
-- Name: materias materias_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materias
    ADD CONSTRAINT materias_nombre_key UNIQUE (nombre);


--
-- Name: materias materias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materias
    ADD CONSTRAINT materias_pkey PRIMARY KEY (id);


--
-- Name: niveles_educativos niveles_educativos_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.niveles_educativos
    ADD CONSTRAINT niveles_educativos_nombre_key UNIQUE (nombre);


--
-- Name: niveles_educativos niveles_educativos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.niveles_educativos
    ADD CONSTRAINT niveles_educativos_pkey PRIMARY KEY (id);


--
-- Name: padres padres_dpi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.padres
    ADD CONSTRAINT padres_dpi_key UNIQUE (dpi);


--
-- Name: padres padres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.padres
    ADD CONSTRAINT padres_pkey PRIMARY KEY (id);


--
-- Name: pagos_bus pagos_bus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos_bus
    ADD CONSTRAINT pagos_bus_pkey PRIMARY KEY (id);


--
-- Name: pagos pagos_numero_recibo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_numero_recibo_key UNIQUE (numero_recibo);


--
-- Name: pagos pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (id);


--
-- Name: periodos_academicos periodos_academicos_nombre_ano_academico_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_academicos
    ADD CONSTRAINT periodos_academicos_nombre_ano_academico_key UNIQUE (nombre, ano_academico);


--
-- Name: periodos_academicos periodos_academicos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_academicos
    ADD CONSTRAINT periodos_academicos_pkey PRIMARY KEY (id);


--
-- Name: permisos permisos_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_codigo_key UNIQUE (codigo);


--
-- Name: permisos permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_pkey PRIMARY KEY (id);


--
-- Name: roles roles_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_nombre_key UNIQUE (nombre);


--
-- Name: roles_permisos roles_permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_pkey PRIMARY KEY (id);


--
-- Name: roles_permisos roles_permisos_rol_id_permiso_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_rol_id_permiso_id_key UNIQUE (rol_id, permiso_id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: secciones secciones_grado_id_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secciones
    ADD CONSTRAINT secciones_grado_id_nombre_key UNIQUE (grado_id, nombre);


--
-- Name: secciones secciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secciones
    ADD CONSTRAINT secciones_pkey PRIMARY KEY (id);


--
-- Name: servicio_bus servicio_bus_estudiante_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_bus
    ADD CONSTRAINT servicio_bus_estudiante_id_key UNIQUE (estudiante_id);


--
-- Name: servicio_bus servicio_bus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_bus
    ADD CONSTRAINT servicio_bus_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_username_key UNIQUE (username);


--
-- Name: idx_actividades_docente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_actividades_docente ON public.actividades USING btree (docente_id);


--
-- Name: idx_actividades_grado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_actividades_grado ON public.actividades USING btree (grado_id);


--
-- Name: idx_actividades_materia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_actividades_materia ON public.actividades USING btree (materia_id);


--
-- Name: idx_actividades_periodo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_actividades_periodo ON public.actividades USING btree (periodo);


--
-- Name: idx_asistencia_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asistencia_estado ON public.asistencia USING btree (estado);


--
-- Name: idx_asistencia_estudiante; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asistencia_estudiante ON public.asistencia USING btree (estudiante_id);


--
-- Name: idx_asistencia_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asistencia_fecha ON public.asistencia USING btree (fecha);


--
-- Name: idx_calificaciones_actividad_actividad; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calificaciones_actividad_actividad ON public.calificaciones_actividad USING btree (actividad_id);


--
-- Name: idx_calificaciones_actividad_estudiante; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calificaciones_actividad_estudiante ON public.calificaciones_actividad USING btree (estudiante_id);


--
-- Name: idx_calificaciones_ano; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calificaciones_ano ON public.calificaciones USING btree (ano_academico);


--
-- Name: idx_calificaciones_docente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calificaciones_docente ON public.calificaciones USING btree (docente_id);


--
-- Name: idx_calificaciones_estudiante; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calificaciones_estudiante ON public.calificaciones USING btree (estudiante_id);


--
-- Name: idx_calificaciones_grado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calificaciones_grado ON public.calificaciones USING btree (grado_id);


--
-- Name: idx_calificaciones_materia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calificaciones_materia ON public.calificaciones USING btree (materia_id);


--
-- Name: idx_calificaciones_periodo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calificaciones_periodo ON public.calificaciones USING btree (periodo);


--
-- Name: idx_estudiantes_codigo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_estudiantes_codigo ON public.estudiantes USING btree (codigo);


--
-- Name: idx_estudiantes_dpi; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_estudiantes_dpi ON public.estudiantes USING btree (dpi);


--
-- Name: idx_grados_docentes_ano; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grados_docentes_ano ON public.grados_docentes USING btree (ano_academico);


--
-- Name: idx_grados_docentes_docente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grados_docentes_docente ON public.grados_docentes USING btree (docente_id);


--
-- Name: idx_grados_docentes_grado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grados_docentes_grado ON public.grados_docentes USING btree (grado_id);


--
-- Name: idx_grados_materias_docentes_ano; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grados_materias_docentes_ano ON public.grados_materias_docentes USING btree (ano_academico);


--
-- Name: idx_grados_materias_docentes_docente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grados_materias_docentes_docente ON public.grados_materias_docentes USING btree (docente_id);


--
-- Name: idx_grados_materias_docentes_grado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grados_materias_docentes_grado ON public.grados_materias_docentes USING btree (grado_id);


--
-- Name: idx_grados_materias_docentes_materia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grados_materias_docentes_materia ON public.grados_materias_docentes USING btree (materia_id);


--
-- Name: idx_materias_docentes_docente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materias_docentes_docente ON public.materias_docentes USING btree (docente_id);


--
-- Name: idx_materias_docentes_materia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materias_docentes_materia ON public.materias_docentes USING btree (materia_id);


--
-- Name: idx_pagos_bus_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_bus_estado ON public.pagos_bus USING btree (estado);


--
-- Name: idx_pagos_bus_estudiante; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_bus_estudiante ON public.pagos_bus USING btree (estudiante_id);


--
-- Name: idx_pagos_bus_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_bus_fecha ON public.pagos_bus USING btree (fecha_pago);


--
-- Name: idx_pagos_bus_mes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_bus_mes ON public.pagos_bus USING btree (mes);


--
-- Name: idx_pagos_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_estado ON public.pagos USING btree (estado);


--
-- Name: idx_pagos_estudiante; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_estudiante ON public.pagos USING btree (estudiante_id);


--
-- Name: idx_pagos_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_fecha ON public.pagos USING btree (fecha_pago);


--
-- Name: idx_pagos_mes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_mes ON public.pagos USING btree (mes);


--
-- Name: idx_servicio_bus_activo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_servicio_bus_activo ON public.servicio_bus USING btree (activo);


--
-- Name: idx_servicio_bus_estudiante; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_servicio_bus_estudiante ON public.servicio_bus USING btree (estudiante_id);


--
-- Name: calificaciones_actividad trigger_actualizar_nota_final; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_actualizar_nota_final AFTER INSERT OR UPDATE ON public.calificaciones_actividad FOR EACH ROW EXECUTE FUNCTION public.actualizar_nota_final_trigger();


--
-- Name: asistencia trigger_update_asistencia_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_asistencia_timestamp BEFORE UPDATE ON public.asistencia FOR EACH ROW EXECUTE FUNCTION public.update_asistencia_timestamp();


--
-- Name: calificaciones_actividad trigger_update_calificaciones_actividad_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_calificaciones_actividad_timestamp BEFORE UPDATE ON public.calificaciones_actividad FOR EACH ROW EXECUTE FUNCTION public.update_calificaciones_actividad_timestamp();


--
-- Name: calificaciones trigger_update_calificaciones_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_calificaciones_timestamp BEFORE UPDATE ON public.calificaciones FOR EACH ROW EXECUTE FUNCTION public.update_calificaciones_timestamp();


--
-- Name: actividades actividades_docente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actividades
    ADD CONSTRAINT actividades_docente_id_fkey FOREIGN KEY (docente_id) REFERENCES public.usuarios(id);


--
-- Name: actividades actividades_grado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actividades
    ADD CONSTRAINT actividades_grado_id_fkey FOREIGN KEY (grado_id) REFERENCES public.grados(id);


--
-- Name: actividades actividades_materia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actividades
    ADD CONSTRAINT actividades_materia_id_fkey FOREIGN KEY (materia_id) REFERENCES public.materias(id);


--
-- Name: actividades actividades_periodo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actividades
    ADD CONSTRAINT actividades_periodo_id_fkey FOREIGN KEY (periodo_id) REFERENCES public.periodos_academicos(id);


--
-- Name: actividades actividades_seccion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actividades
    ADD CONSTRAINT actividades_seccion_id_fkey FOREIGN KEY (seccion_id) REFERENCES public.secciones(id);


--
-- Name: asistencia asistencia_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencia
    ADD CONSTRAINT asistencia_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id) ON DELETE CASCADE;


--
-- Name: asistencias asistencias_autorizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencias
    ADD CONSTRAINT asistencias_autorizado_por_fkey FOREIGN KEY (autorizado_por) REFERENCES public.usuarios(id);


--
-- Name: asistencias asistencias_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencias
    ADD CONSTRAINT asistencias_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id) ON DELETE CASCADE;


--
-- Name: auditoria auditoria_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;


--
-- Name: calificaciones_actividad calificaciones_actividad_actividad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividad
    ADD CONSTRAINT calificaciones_actividad_actividad_id_fkey FOREIGN KEY (actividad_id) REFERENCES public.actividades(id) ON DELETE CASCADE;


--
-- Name: calificaciones_actividad calificaciones_actividad_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividad
    ADD CONSTRAINT calificaciones_actividad_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id) ON DELETE CASCADE;


--
-- Name: calificaciones_actividades calificaciones_actividades_actividad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividades
    ADD CONSTRAINT calificaciones_actividades_actividad_id_fkey FOREIGN KEY (actividad_id) REFERENCES public.actividades(id) ON DELETE CASCADE;


--
-- Name: calificaciones_actividades calificaciones_actividades_calificado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividades
    ADD CONSTRAINT calificaciones_actividades_calificado_por_fkey FOREIGN KEY (calificado_por) REFERENCES public.usuarios(id);


--
-- Name: calificaciones_actividades calificaciones_actividades_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones_actividades
    ADD CONSTRAINT calificaciones_actividades_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id) ON DELETE CASCADE;


--
-- Name: calificaciones calificaciones_docente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones
    ADD CONSTRAINT calificaciones_docente_id_fkey FOREIGN KEY (docente_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: calificaciones calificaciones_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones
    ADD CONSTRAINT calificaciones_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id) ON DELETE CASCADE;


--
-- Name: calificaciones calificaciones_grado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones
    ADD CONSTRAINT calificaciones_grado_id_fkey FOREIGN KEY (grado_id) REFERENCES public.grados(id) ON DELETE CASCADE;


--
-- Name: calificaciones calificaciones_materia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calificaciones
    ADD CONSTRAINT calificaciones_materia_id_fkey FOREIGN KEY (materia_id) REFERENCES public.materias(id) ON DELETE CASCADE;


--
-- Name: estado_cuenta_estudiante estado_cuenta_estudiante_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estado_cuenta_estudiante
    ADD CONSTRAINT estado_cuenta_estudiante_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id) ON DELETE CASCADE;


--
-- Name: estudiantes estudiantes_grado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes
    ADD CONSTRAINT estudiantes_grado_id_fkey FOREIGN KEY (grado_id) REFERENCES public.grados(id);


--
-- Name: estudiantes_padres estudiantes_padres_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes_padres
    ADD CONSTRAINT estudiantes_padres_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id) ON DELETE CASCADE;


--
-- Name: estudiantes_padres estudiantes_padres_padre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estudiantes_padres
    ADD CONSTRAINT estudiantes_padres_padre_id_fkey FOREIGN KEY (padre_id) REFERENCES public.padres(id) ON DELETE RESTRICT;


--
-- Name: grados_docentes grados_docentes_docente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_docentes
    ADD CONSTRAINT grados_docentes_docente_id_fkey FOREIGN KEY (docente_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: grados_docentes grados_docentes_grado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_docentes
    ADD CONSTRAINT grados_docentes_grado_id_fkey FOREIGN KEY (grado_id) REFERENCES public.grados(id) ON DELETE CASCADE;


--
-- Name: grados_materias_docentes grados_materias_docentes_docente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_materias_docentes
    ADD CONSTRAINT grados_materias_docentes_docente_id_fkey FOREIGN KEY (docente_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: grados_materias_docentes grados_materias_docentes_grado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_materias_docentes
    ADD CONSTRAINT grados_materias_docentes_grado_id_fkey FOREIGN KEY (grado_id) REFERENCES public.grados(id) ON DELETE CASCADE;


--
-- Name: grados_materias_docentes grados_materias_docentes_materia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados_materias_docentes
    ADD CONSTRAINT grados_materias_docentes_materia_id_fkey FOREIGN KEY (materia_id) REFERENCES public.materias(id) ON DELETE CASCADE;


--
-- Name: grados grados_nivel_educativo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grados
    ADD CONSTRAINT grados_nivel_educativo_id_fkey FOREIGN KEY (nivel_educativo_id) REFERENCES public.niveles_educativos(id);


--
-- Name: materias_docentes materias_docentes_docente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materias_docentes
    ADD CONSTRAINT materias_docentes_docente_id_fkey FOREIGN KEY (docente_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: materias_docentes materias_docentes_materia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materias_docentes
    ADD CONSTRAINT materias_docentes_materia_id_fkey FOREIGN KEY (materia_id) REFERENCES public.materias(id) ON DELETE CASCADE;


--
-- Name: pagos pagos_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id);


--
-- Name: pagos_bus pagos_bus_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos_bus
    ADD CONSTRAINT pagos_bus_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id);


--
-- Name: pagos_bus pagos_bus_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos_bus
    ADD CONSTRAINT pagos_bus_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id);


--
-- Name: pagos_bus pagos_bus_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos_bus
    ADD CONSTRAINT pagos_bus_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id) ON DELETE CASCADE;


--
-- Name: pagos pagos_concepto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_concepto_id_fkey FOREIGN KEY (concepto_id) REFERENCES public.conceptos_pago(id);


--
-- Name: pagos pagos_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id);


--
-- Name: pagos pagos_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id);


--
-- Name: pagos pagos_registrado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_registrado_por_fkey FOREIGN KEY (registrado_por) REFERENCES public.usuarios(id);


--
-- Name: pagos pagos_verificado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_verificado_por_fkey FOREIGN KEY (verificado_por) REFERENCES public.usuarios(id);


--
-- Name: roles_permisos roles_permisos_permiso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_permiso_id_fkey FOREIGN KEY (permiso_id) REFERENCES public.permisos(id) ON DELETE CASCADE;


--
-- Name: roles_permisos roles_permisos_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: secciones secciones_grado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secciones
    ADD CONSTRAINT secciones_grado_id_fkey FOREIGN KEY (grado_id) REFERENCES public.grados(id) ON DELETE CASCADE;


--
-- Name: servicio_bus servicio_bus_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_bus
    ADD CONSTRAINT servicio_bus_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id);


--
-- Name: servicio_bus servicio_bus_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_bus
    ADD CONSTRAINT servicio_bus_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id);


--
-- Name: servicio_bus servicio_bus_estudiante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_bus
    ADD CONSTRAINT servicio_bus_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id) ON DELETE CASCADE;


--
-- Name: usuarios usuarios_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id);


--
-- PostgreSQL database dump complete
--

