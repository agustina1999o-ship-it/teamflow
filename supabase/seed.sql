-- ============================================================
-- TeamFlow — Datos iniciales de demo (seed)
-- Ejecutar DESPUÉS del schema.sql
-- IMPORTANTE: Reemplazar los UUIDs de auth.users con los reales
-- que Supabase genere al crear los usuarios via Authentication.
-- ============================================================

-- Usuarios reales del equipo:
--   apenafort@llyasoc.com   → Gerente 1 (ADMIN)
--   abarelli@llyasoc.com    → Gerente 2 (ADMIN)
--   cestevez@llyasoc.com    → Senior   (ADMIN)
--   malifraco@llyasoc.com   → SemiSenior (EDITOR)
--   mamagallanes@llyasoc.com → Junior  (EDITOR)

-- PASO 2: Copiar los UUIDs generados y reemplazar aquí:
DO $$
DECLARE
    u1 UUID; -- Gerente 1
    u2 UUID; -- Gerente 2
    u3 UUID; -- Senior
    u4 UUID; -- SemiSenior
    u5 UUID; -- Junior
    p1 UUID; -- Proyecto ERP
    p2 UUID; -- Proyecto Portal
    p3 UUID; -- Proyecto Interno
    s1 UUID; s2 UUID; s3 UUID; s4 UUID; s5 UUID; s6 UUID; -- Etapas P1
    t1 UUID; t2 UUID; t3 UUID; t4 UUID; t5 UUID; t6 UUID; t7 UUID; t8 UUID; t9 UUID; -- Tareas
BEGIN
    -- Obtener IDs de auth.users por email
    SELECT id INTO u1 FROM auth.users WHERE email = 'apenafort@llyasoc.com' LIMIT 1;
    SELECT id INTO u2 FROM auth.users WHERE email = 'abarelli@llyasoc.com' LIMIT 1;
    SELECT id INTO u3 FROM auth.users WHERE email = 'cestevez@llyasoc.com' LIMIT 1;
    SELECT id INTO u4 FROM auth.users WHERE email = 'malifraco@llyasoc.com' LIMIT 1;
    SELECT id INTO u5 FROM auth.users WHERE email = 'mamagallanes@llyasoc.com' LIMIT 1;

    -- Insertar perfiles
    INSERT INTO profiles (id, nombre, username, rol, horas_disponibles_default, avatar_color) VALUES
        (u1, 'A. Penafort',    'apenafort',    'gerente',    160, '#3b82f6'),
        (u2, 'A. Barelli',     'abarelli',     'gerente',    160, '#8b5cf6'),
        (u3, 'C. Estevez',     'cestevez',     'senior',     160, '#10b981'),
        (u4, 'M. Alifraco',    'malifraco',    'semisénior', 160, '#f59e0b'),
        (u5, 'M. Magallanes',  'mamagallanes', 'junior',     160, '#ef4444')
    ON CONFLICT (id) DO NOTHING;

    -- ============================================================
    -- PROYECTOS
    -- ============================================================
    p1 := gen_random_uuid();
    INSERT INTO projects (id, nombre, tipo, cliente, descripcion, fecha_inicio, fecha_fin,
        estado, prioridad, color, presupuesto_horas, nivel_riesgo, created_by)
    VALUES (p1, 'Migración ERP', 'cliente', 'Acme S.A.',
        'Migración completa del sistema ERP legacy a la nueva plataforma cloud. Incluye migración de datos históricos y capacitación.',
        DATE_TRUNC('year', CURRENT_DATE),
        DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '5 months 30 days',
        'activo', 'alta', '#3b82f6', 800, 'medio', u1);

    p2 := gen_random_uuid();
    INSERT INTO projects (id, nombre, tipo, cliente, descripcion, fecha_inicio, fecha_fin,
        estado, prioridad, color, presupuesto_horas, nivel_riesgo, created_by)
    VALUES (p2, 'Portal de Autogestión', 'cliente', 'Beta Corp',
        'Desarrollo de portal web para que los empleados gestionen sus solicitudes de RRHH, vacaciones y documentación.',
        DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '3 months',
        DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '7 months 30 days',
        'planificado', 'media', '#8b5cf6', 400, 'sin_riesgo', u1);

    p3 := gen_random_uuid();
    INSERT INTO projects (id, nombre, tipo, descripcion, fecha_inicio, fecha_fin,
        estado, prioridad, color, presupuesto_horas, created_by)
    VALUES (p3, 'Mejora de Procesos Internos', 'interno',
        'Revisión y optimización de los procesos de desarrollo del equipo. Implementar metodologías ágiles y mejorar la documentación.',
        DATE_TRUNC('year', CURRENT_DATE),
        DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '11 months 30 days',
        'activo', 'baja', '#10b981', 200, u2);

    -- ============================================================
    -- MIEMBROS DE PROYECTO
    -- ============================================================
    INSERT INTO project_members (project_id, user_id) VALUES
        (p1, u1), (p1, u2), (p1, u3), (p1, u4),
        (p2, u1), (p2, u3), (p2, u4), (p2, u5),
        (p3, u2), (p3, u3), (p3, u4), (p3, u5);

    -- ============================================================
    -- ETAPAS — Proyecto 1 (Migración ERP)
    -- ============================================================
    s1 := gen_random_uuid();
    INSERT INTO project_stages (id, project_id, nombre, peso, valor_avance, responsable_id, orden)
    VALUES (s1, p1, 'Análisis y Relevamiento', 8, 3, u3, 1);

    s2 := gen_random_uuid();
    INSERT INTO project_stages (id, project_id, nombre, peso, valor_avance, responsable_id, orden)
    VALUES (s2, p1, 'Diseño de Arquitectura', 7, 2, u3, 2);

    s3 := gen_random_uuid();
    INSERT INTO project_stages (id, project_id, nombre, peso, valor_avance, responsable_id, orden)
    VALUES (s3, p1, 'Migración de Datos', 9, 1, u4, 3);

    s4 := gen_random_uuid();
    INSERT INTO project_stages (id, project_id, nombre, peso, valor_avance, responsable_id, orden)
    VALUES (s4, p1, 'Configuración del Sistema', 8, 0, u4, 4);

    s5 := gen_random_uuid();
    INSERT INTO project_stages (id, project_id, nombre, peso, valor_avance, responsable_id, orden)
    VALUES (s5, p1, 'Testing y QA', 7, 0, u5, 5);

    s6 := gen_random_uuid();
    INSERT INTO project_stages (id, project_id, nombre, peso, valor_avance, responsable_id, orden)
    VALUES (s6, p1, 'Go-Live y Capacitación', 6, 0, u1, 6);

    -- Etapas Proyecto 2 (Portal)
    INSERT INTO project_stages (id, project_id, nombre, peso, valor_avance, responsable_id, orden) VALUES
        (gen_random_uuid(), p2, 'UX Research', 6, 0, u3, 1),
        (gen_random_uuid(), p2, 'Wireframes', 5, 0, u3, 2),
        (gen_random_uuid(), p2, 'Desarrollo Frontend', 8, 0, u4, 3),
        (gen_random_uuid(), p2, 'Desarrollo Backend', 8, 0, u5, 4),
        (gen_random_uuid(), p2, 'QA y Testing', 6, 0, u4, 5),
        (gen_random_uuid(), p2, 'Deploy', 4, 0, u3, 6);

    -- Etapas Proyecto 3 (Interno)
    INSERT INTO project_stages (id, project_id, nombre, peso, valor_avance, responsable_id, orden) VALUES
        (gen_random_uuid(), p3, 'Diagnóstico', 7, 3, u2, 1),
        (gen_random_uuid(), p3, 'Plan de Acción', 6, 2, u2, 2),
        (gen_random_uuid(), p3, 'Implementación', 8, 1, u3, 3),
        (gen_random_uuid(), p3, 'Seguimiento', 5, 0, u3, 4);

    -- ============================================================
    -- TAREAS
    -- ============================================================
    t1 := gen_random_uuid();
    INSERT INTO tasks (id, project_id, stage_id, titulo, descripcion, asignado_a, estado, prioridad, fecha_limite, horas_estimadas, created_by)
    VALUES (t1, p1, s3, 'Mapeo de tablas legacy → nuevo schema', 'Analizar todas las tablas del sistema antiguo y definir la correspondencia en el nuevo modelo de datos.', u4, 'en_progreso', 'alta', CURRENT_DATE + INTERVAL '7 days', 24, u1);

    t2 := gen_random_uuid();
    INSERT INTO tasks (id, project_id, stage_id, titulo, descripcion, asignado_a, estado, prioridad, fecha_limite, horas_estimadas, created_by)
    VALUES (t2, p1, s3, 'Script de migración de datos históricos', 'Desarrollar scripts Python para migrar 5 años de datos transaccionales.', u4, 'pendiente', 'alta', CURRENT_DATE + INTERVAL '14 days', 40, u1);

    t3 := gen_random_uuid();
    INSERT INTO tasks (id, project_id, stage_id, titulo, descripcion, asignado_a, estado, prioridad, fecha_limite, horas_estimadas, created_by)
    VALUES (t3, p1, s2, 'Documento de arquitectura cloud', 'Redactar el documento de arquitectura final con diagramas de infraestructura.', u3, 'completada', 'media', CURRENT_DATE - INTERVAL '5 days', 16, u2);

    t4 := gen_random_uuid();
    INSERT INTO tasks (id, project_id, stage_id, titulo, descripcion, asignado_a, estado, prioridad, fecha_limite, horas_estimadas, created_by)
    VALUES (t4, p1, s5, 'Plan de pruebas de regresión', 'Diseñar el plan completo de testing incluyendo casos de prueba unitarios e integración.', u5, 'pendiente', 'alta', CURRENT_DATE + INTERVAL '21 days', 20, u1);

    t5 := gen_random_uuid();
    INSERT INTO tasks (id, project_id, stage_id, titulo, descripcion, asignado_a, estado, prioridad, fecha_limite, horas_estimadas, created_by)
    VALUES (t5, p2, NULL, 'Research de usuarios y personas', 'Conducir 5 entrevistas con usuarios finales y generar el documento de personas.', u3, 'pendiente', 'alta', CURRENT_DATE + INTERVAL '30 days', 12, u2);

    t6 := gen_random_uuid();
    INSERT INTO tasks (id, project_id, stage_id, titulo, descripcion, asignado_a, estado, prioridad, fecha_limite, horas_estimadas, created_by)
    VALUES (t6, p2, NULL, 'Setup del entorno de desarrollo', 'Configurar repositorio, CI/CD, entornos de dev/staging/prod.', u4, 'pendiente', 'media', CURRENT_DATE + INTERVAL '35 days', 8, u2);

    t7 := gen_random_uuid();
    INSERT INTO tasks (id, project_id, stage_id, titulo, descripcion, asignado_a, estado, prioridad, fecha_limite, horas_estimadas, created_by)
    VALUES (t7, p2, NULL, 'Diseño del sistema de autenticación', 'Implementar SSO con el directorio activo de la empresa cliente.', u5, 'pendiente', 'alta', CURRENT_DATE + INTERVAL '45 days', 20, u1);

    t8 := gen_random_uuid();
    INSERT INTO tasks (id, project_id, stage_id, titulo, descripcion, asignado_a, estado, prioridad, fecha_limite, horas_estimadas, created_by)
    VALUES (t8, p3, NULL, 'Encuesta de satisfacción del equipo', 'Diseñar y enviar encuesta anónima para identificar puntos de mejora en los procesos actuales.', u4, 'completada', 'baja', CURRENT_DATE - INTERVAL '10 days', 4, u2);

    t9 := gen_random_uuid();
    INSERT INTO tasks (id, project_id, stage_id, titulo, descripcion, asignado_a, estado, prioridad, fecha_limite, horas_estimadas, created_by)
    VALUES (t9, p3, NULL, 'Implementar daily standup asíncrono', 'Configurar herramienta de standups async y capacitar al equipo.', u5, 'en_progreso', 'media', CURRENT_DATE + INTERVAL '7 days', 6, u2);

    -- ============================================================
    -- HORAS PLANIFICADAS (año actual)
    -- ============================================================
    INSERT INTO hour_assignments (project_id, user_id, mes, anio, horas_planificadas) VALUES
        -- Proyecto 1 (ERP) - meses 1-6
        (p1, u3, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 80),
        (p1, u3, 2, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 80),
        (p1, u3, 3, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 60),
        (p1, u4, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 100),
        (p1, u4, 2, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 120),
        (p1, u4, 3, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 100),
        (p1, u1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 40),
        (p1, u1, 2, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 40),
        -- Proyecto 3 (Interno) - todo el año
        (p3, u2, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 20),
        (p3, u2, 2, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 20),
        (p3, u3, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 20),
        (p3, u4, 2, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 20),
        (p3, u5, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, 20)
    ON CONFLICT (project_id, user_id, mes, anio) DO NOTHING;

    -- ============================================================
    -- VACACIONES
    -- ============================================================
    INSERT INTO vacations (user_id, fecha_inicio, fecha_fin, tipo, descripcion, created_by) VALUES
        (u4, DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '14 days',
              DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '30 days',
              'vacaciones', 'Vacaciones de verano', u1),
        (u5, DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '31 days',
              DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '45 days',
              'vacaciones', 'Vacaciones de verano', u1);

    -- ============================================================
    -- NOTAS DE PROYECTOS
    -- ============================================================
    INSERT INTO project_notes (project_id, user_id, contenido) VALUES
        (p1, u1, 'Reunión con el cliente confirmada para la próxima semana. Revisar entregables pendientes antes del jueves.'),
        (p1, u3, 'El mapeo de tablas está siendo más complejo de lo esperado. El módulo de facturación tiene dependencias circulares que hay que resolver.'),
        (p3, u2, 'Primeros resultados de la encuesta recibidos. El 80% del equipo pide más instancias de feedback.');

END $$;
