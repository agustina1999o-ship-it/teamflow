-- ============================================================
-- TeamFlow — Schema completo para Supabase (PostgreSQL)
-- Ejecutar en: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- TABLA 1: profiles (extiende auth.users de Supabase)
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    rol TEXT NOT NULL DEFAULT 'junior' CHECK (rol IN ('gerente','senior','semisenior','junior')),
    horas_disponibles_default INTEGER NOT NULL DEFAULT 160,
    avatar_color TEXT NOT NULL DEFAULT '#3b82f6',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLA 2: projects
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL DEFAULT 'interno' CHECK (tipo IN ('cliente','interno')),
    cliente TEXT,
    descripcion TEXT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado TEXT NOT NULL DEFAULT 'planificado' CHECK (estado IN ('planificado','activo','pausado','finalizado','cancelado')),
    prioridad TEXT NOT NULL DEFAULT 'media' CHECK (prioridad IN ('alta','media','baja')),
    color TEXT NOT NULL DEFAULT '#3b82f6',
    presupuesto_horas INTEGER NOT NULL DEFAULT 0,
    nivel_riesgo TEXT NOT NULL DEFAULT 'sin_riesgo' CHECK (nivel_riesgo IN ('sin_riesgo','bajo','medio','critico')),
    riesgo_comentario TEXT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLA 3: project_members
-- ============================================================
CREATE TABLE IF NOT EXISTS project_members (
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    PRIMARY KEY (project_id, user_id)
);

-- ============================================================
-- TABLA 4: project_stages (etapas customizables)
-- ============================================================
CREATE TABLE IF NOT EXISTS project_stages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    peso INTEGER NOT NULL DEFAULT 5 CHECK (peso BETWEEN 1 AND 10),
    valor_avance INTEGER NOT NULL DEFAULT 0 CHECK (valor_avance BETWEEN 0 AND 3),
    responsable_id UUID REFERENCES profiles(id),
    orden INTEGER NOT NULL DEFAULT 0,
    updated_by UUID REFERENCES profiles(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLA 5: tasks
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    stage_id UUID REFERENCES project_stages(id) ON DELETE SET NULL,
    titulo TEXT NOT NULL,
    descripcion TEXT,
    asignado_a UUID REFERENCES profiles(id),
    estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','en_progreso','bloqueada','completada')),
    prioridad TEXT NOT NULL DEFAULT 'media' CHECK (prioridad IN ('alta','media','baja')),
    fecha_limite DATE,
    horas_estimadas NUMERIC(6,2) DEFAULT 0,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLA 6: task_comments
-- ============================================================
CREATE TABLE IF NOT EXISTS task_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id),
    comentario TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLA 7: hour_assignments (horas planificadas por mes)
-- ============================================================
CREATE TABLE IF NOT EXISTS hour_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    mes INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
    anio INTEGER NOT NULL,
    horas_planificadas NUMERIC(6,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (project_id, user_id, mes, anio)
);

-- ============================================================
-- TABLA 8: hour_actuals (horas reales por semana)
-- ============================================================
CREATE TABLE IF NOT EXISTS hour_actuals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    semana_inicio DATE NOT NULL,
    horas_reales NUMERIC(6,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (project_id, user_id, semana_inicio)
);

-- ============================================================
-- TABLA 9: user_capacity (capacidad mensual configurable)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_capacity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    mes INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
    anio INTEGER NOT NULL,
    horas_disponibles NUMERIC(6,2) NOT NULL DEFAULT 160,
    UNIQUE (user_id, mes, anio)
);

-- ============================================================
-- TABLA 10: vacations
-- ============================================================
CREATE TABLE IF NOT EXISTS vacations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    tipo TEXT NOT NULL DEFAULT 'vacaciones' CHECK (tipo IN ('vacaciones','licencia','feriado')),
    descripcion TEXT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLA 11: project_notes (notas colaborativas)
-- ============================================================
CREATE TABLE IF NOT EXISTS project_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id),
    contenido TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLA 12: audit_log
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tabla_afectada TEXT NOT NULL,
    registro_id UUID,
    accion TEXT NOT NULL,
    descripcion TEXT,
    valor_anterior JSONB,
    valor_nuevo JSONB,
    user_id UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- FUNCIÓN: Calcular avance automático del proyecto
-- ============================================================
CREATE OR REPLACE FUNCTION calcular_avance_proyecto(p_id UUID)
RETURNS NUMERIC AS $$
    SELECT CASE
        WHEN SUM(peso * 3) = 0 THEN 0
        ELSE ROUND(SUM(peso * valor_avance)::NUMERIC / SUM(peso * 3) * 100, 1)
    END
    FROM project_stages
    WHERE project_id = p_id;
$$ LANGUAGE SQL STABLE;

-- ============================================================
-- FUNCIÓN: Trigger para actualizar updated_at automáticamente
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE OR REPLACE TRIGGER trg_projects_updated_at
    BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_tasks_updated_at
    BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE hour_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE hour_actuals ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_capacity ENABLE ROW LEVEL SECURITY;
ALTER TABLE vacations ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Función helper para obtener rol del usuario actual
CREATE OR REPLACE FUNCTION get_user_rol()
RETURNS TEXT AS $$
    SELECT rol FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ---- PROFILES ----
CREATE POLICY "Todos pueden ver perfiles" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Solo admin edita perfiles ajenos" ON profiles FOR UPDATE TO authenticated
    USING (id = auth.uid() OR get_user_rol() IN ('gerente','senior'));
CREATE POLICY "Insert propio perfil" ON profiles FOR INSERT TO authenticated WITH CHECK (id = auth.uid());

-- ---- PROJECTS ----
CREATE POLICY "Admin ve todos los proyectos" ON projects FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR
           id IN (SELECT project_id FROM project_members WHERE user_id = auth.uid()));

CREATE POLICY "Solo admin crea proyectos" ON projects FOR INSERT TO authenticated
    WITH CHECK (get_user_rol() IN ('gerente','senior'));

CREATE POLICY "Solo admin edita proyectos" ON projects FOR UPDATE TO authenticated
    USING (get_user_rol() IN ('gerente','senior'));

CREATE POLICY "Solo gerente elimina proyectos" ON projects FOR DELETE TO authenticated
    USING (get_user_rol() = 'gerente');

-- ---- PROJECT_MEMBERS ----
CREATE POLICY "Autenticados ven miembros" ON project_members FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin gestiona miembros" ON project_members FOR ALL TO authenticated
    USING (get_user_rol() IN ('gerente','senior'));

-- ---- PROJECT_STAGES ----
CREATE POLICY "Ver etapas de proyectos propios" ON project_stages FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR
           project_id IN (SELECT project_id FROM project_members WHERE user_id = auth.uid()));

CREATE POLICY "Admin crea/edita etapas" ON project_stages FOR INSERT TO authenticated
    WITH CHECK (get_user_rol() IN ('gerente','senior'));

CREATE POLICY "Admin o responsable edita avance" ON project_stages FOR UPDATE TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR responsable_id = auth.uid());

CREATE POLICY "Admin elimina etapas" ON project_stages FOR DELETE TO authenticated
    USING (get_user_rol() IN ('gerente','senior'));

-- ---- TASKS ----
CREATE POLICY "Ver tareas propias o admin" ON tasks FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR asignado_a = auth.uid() OR
           project_id IN (SELECT project_id FROM project_members WHERE user_id = auth.uid()));

CREATE POLICY "Admin crea tareas" ON tasks FOR INSERT TO authenticated
    WITH CHECK (get_user_rol() IN ('gerente','senior'));

CREATE POLICY "Admin edita o asignado cambia estado" ON tasks FOR UPDATE TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR asignado_a = auth.uid());

CREATE POLICY "Admin elimina tareas" ON tasks FOR DELETE TO authenticated
    USING (get_user_rol() IN ('gerente','senior'));

-- ---- TASK_COMMENTS ----
CREATE POLICY "Ver comentarios de tareas propias" ON task_comments FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR
           task_id IN (SELECT id FROM tasks WHERE asignado_a = auth.uid() OR
                       project_id IN (SELECT project_id FROM project_members WHERE user_id = auth.uid())));
CREATE POLICY "Insertar comentario propio" ON task_comments FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- ---- HOUR_ASSIGNMENTS ----
CREATE POLICY "Admin ve todas las horas" ON hour_assignments FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR user_id = auth.uid());
CREATE POLICY "Admin gestiona horas" ON hour_assignments FOR ALL TO authenticated
    USING (get_user_rol() IN ('gerente','senior'));

-- ---- HOUR_ACTUALS ----
CREATE POLICY "Ver horas reales propias o admin" ON hour_actuals FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR user_id = auth.uid());
CREATE POLICY "Registrar horas reales propias" ON hour_actuals FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() OR get_user_rol() IN ('gerente','senior'));
CREATE POLICY "Editar horas reales propias" ON hour_actuals FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR get_user_rol() IN ('gerente','senior'));

-- ---- USER_CAPACITY ----
CREATE POLICY "Ver capacidad propia o admin" ON user_capacity FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR user_id = auth.uid());
CREATE POLICY "Solo admin modifica capacidad" ON user_capacity FOR ALL TO authenticated
    USING (get_user_rol() IN ('gerente','senior'));

-- ---- VACATIONS ----
CREATE POLICY "Ver vacaciones propias o admin" ON vacations FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR user_id = auth.uid());
CREATE POLICY "Registrar vacaciones propias o admin" ON vacations FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() OR get_user_rol() IN ('gerente','senior'));
CREATE POLICY "Solo gerente elimina vacaciones ajenas" ON vacations FOR DELETE TO authenticated
    USING (user_id = auth.uid() OR get_user_rol() = 'gerente');

-- ---- PROJECT_NOTES ----
CREATE POLICY "Ver notas de proyectos propios" ON project_notes FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior') OR
           project_id IN (SELECT project_id FROM project_members WHERE user_id = auth.uid()));
CREATE POLICY "Cualquiera en el proyecto puede agregar notas" ON project_notes FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() AND (get_user_rol() IN ('gerente','senior') OR
               project_id IN (SELECT project_id FROM project_members WHERE user_id = auth.uid())));

-- ---- AUDIT_LOG ----
CREATE POLICY "Solo admin ve auditoría" ON audit_log FOR SELECT TO authenticated
    USING (get_user_rol() IN ('gerente','senior'));
CREATE POLICY "Sistema inserta en auditoría" ON audit_log FOR INSERT TO authenticated
    WITH CHECK (true);
