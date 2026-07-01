-- ============================================================
-- TeamFlow — Migración Multi-tenant (versión corregida)
-- Ejecutar en: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ============================================================
-- PASO 1: Modificar tabla profiles (agregar columnas primero)
-- ============================================================
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE profiles ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS tenant_id UUID;

-- ============================================================
-- PASO 2: Migrar datos existentes ANTES de crear restricciones
-- ============================================================
UPDATE profiles SET auth_user_id = id WHERE auth_user_id IS NULL;
UPDATE profiles SET tenant_id = id WHERE tenant_id IS NULL;

-- ============================================================
-- PASO 3: Agregar la foreign key a tenant_id ahora que tiene datos
-- ============================================================
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_tenant_id_fkey;
ALTER TABLE profiles ADD CONSTRAINT profiles_tenant_id_fkey
    FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- Unicidad de username por organización (no global)
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_username_key;
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_username_tenant_key;
ALTER TABLE profiles ADD CONSTRAINT profiles_username_tenant_key UNIQUE (tenant_id, username);

-- ============================================================
-- PASO 4: Crear funciones AHORA que las columnas existen
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_my_tenant_id()
RETURNS UUID AS $$
    SELECT tenant_id FROM public.profiles WHERE auth_user_id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_user_rol()
RETURNS TEXT AS $$
    SELECT rol FROM public.profiles WHERE auth_user_id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ============================================================
-- PASO 5: Configurar DEFAULT en profiles.tenant_id
-- ============================================================
ALTER TABLE profiles ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- ============================================================
-- PASO 6: Agregar tenant_id al resto de las tablas
-- ============================================================

-- PROJECTS
ALTER TABLE projects ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE projects SET tenant_id = (SELECT tenant_id FROM profiles WHERE id = created_by) WHERE tenant_id IS NULL;
ALTER TABLE projects DROP CONSTRAINT IF EXISTS projects_tenant_id_fkey;
ALTER TABLE projects ADD CONSTRAINT projects_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE projects ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- PROJECT_MEMBERS
ALTER TABLE project_members ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE project_members SET tenant_id = (SELECT tenant_id FROM projects WHERE id = project_id) WHERE tenant_id IS NULL;
ALTER TABLE project_members DROP CONSTRAINT IF EXISTS project_members_tenant_id_fkey;
ALTER TABLE project_members ADD CONSTRAINT project_members_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE project_members ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- PROJECT_STAGES
ALTER TABLE project_stages ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE project_stages SET tenant_id = (SELECT tenant_id FROM projects WHERE id = project_id) WHERE tenant_id IS NULL;
ALTER TABLE project_stages DROP CONSTRAINT IF EXISTS project_stages_tenant_id_fkey;
ALTER TABLE project_stages ADD CONSTRAINT project_stages_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE project_stages ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- TASKS
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE tasks SET tenant_id = (SELECT tenant_id FROM projects WHERE id = project_id) WHERE tenant_id IS NULL;
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_tenant_id_fkey;
ALTER TABLE tasks ADD CONSTRAINT tasks_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE tasks ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- TASK_COMMENTS
ALTER TABLE task_comments ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE task_comments SET tenant_id = (SELECT tenant_id FROM tasks WHERE id = task_id) WHERE tenant_id IS NULL;
ALTER TABLE task_comments DROP CONSTRAINT IF EXISTS task_comments_tenant_id_fkey;
ALTER TABLE task_comments ADD CONSTRAINT task_comments_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE task_comments ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- HOUR_ASSIGNMENTS
ALTER TABLE hour_assignments ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE hour_assignments SET tenant_id = (SELECT tenant_id FROM profiles WHERE id = user_id) WHERE tenant_id IS NULL;
ALTER TABLE hour_assignments DROP CONSTRAINT IF EXISTS hour_assignments_tenant_id_fkey;
ALTER TABLE hour_assignments ADD CONSTRAINT hour_assignments_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE hour_assignments ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- HOUR_ACTUALS
ALTER TABLE hour_actuals ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE hour_actuals SET tenant_id = (SELECT tenant_id FROM profiles WHERE id = user_id) WHERE tenant_id IS NULL;
ALTER TABLE hour_actuals DROP CONSTRAINT IF EXISTS hour_actuals_tenant_id_fkey;
ALTER TABLE hour_actuals ADD CONSTRAINT hour_actuals_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE hour_actuals ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- USER_CAPACITY
ALTER TABLE user_capacity ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE user_capacity SET tenant_id = (SELECT tenant_id FROM profiles WHERE id = user_id) WHERE tenant_id IS NULL;
ALTER TABLE user_capacity DROP CONSTRAINT IF EXISTS user_capacity_tenant_id_fkey;
ALTER TABLE user_capacity ADD CONSTRAINT user_capacity_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE user_capacity ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- VACATIONS
ALTER TABLE vacations ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE vacations SET tenant_id = (SELECT tenant_id FROM profiles WHERE id = user_id) WHERE tenant_id IS NULL;
ALTER TABLE vacations DROP CONSTRAINT IF EXISTS vacations_tenant_id_fkey;
ALTER TABLE vacations ADD CONSTRAINT vacations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE vacations ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- PROJECT_NOTES
ALTER TABLE project_notes ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE project_notes SET tenant_id = (SELECT tenant_id FROM projects WHERE id = project_id) WHERE tenant_id IS NULL;
ALTER TABLE project_notes DROP CONSTRAINT IF EXISTS project_notes_tenant_id_fkey;
ALTER TABLE project_notes ADD CONSTRAINT project_notes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE project_notes ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- AUDIT_LOG
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS tenant_id UUID;
UPDATE audit_log SET tenant_id = (SELECT tenant_id FROM profiles WHERE id = user_id) WHERE tenant_id IS NULL;
ALTER TABLE audit_log DROP CONSTRAINT IF EXISTS audit_log_tenant_id_fkey;
ALTER TABLE audit_log ADD CONSTRAINT audit_log_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE audit_log ALTER COLUMN tenant_id SET DEFAULT public.get_my_tenant_id();

-- ============================================================
-- PASO 7: Borrar políticas viejas y crear nuevas con aislamiento
-- ============================================================
DROP POLICY IF EXISTS "Todos pueden ver perfiles" ON profiles;
DROP POLICY IF EXISTS "Solo admin edita perfiles ajenos" ON profiles;
DROP POLICY IF EXISTS "Insert propio perfil" ON profiles;
DROP POLICY IF EXISTS "Admin ve todos los proyectos" ON projects;
DROP POLICY IF EXISTS "Solo admin crea proyectos" ON projects;
DROP POLICY IF EXISTS "Solo admin edita proyectos" ON projects;
DROP POLICY IF EXISTS "Solo gerente elimina proyectos" ON projects;
DROP POLICY IF EXISTS "Autenticados ven miembros" ON project_members;
DROP POLICY IF EXISTS "Admin gestiona miembros" ON project_members;
DROP POLICY IF EXISTS "Ver etapas de proyectos propios" ON project_stages;
DROP POLICY IF EXISTS "Admin crea/edita etapas" ON project_stages;
DROP POLICY IF EXISTS "Admin o responsable edita avance" ON project_stages;
DROP POLICY IF EXISTS "Admin elimina etapas" ON project_stages;
DROP POLICY IF EXISTS "Ver tareas propias o admin" ON tasks;
DROP POLICY IF EXISTS "Admin crea tareas" ON tasks;
DROP POLICY IF EXISTS "Admin edita o asignado cambia estado" ON tasks;
DROP POLICY IF EXISTS "Admin elimina tareas" ON tasks;
DROP POLICY IF EXISTS "Ver comentarios de tareas propias" ON task_comments;
DROP POLICY IF EXISTS "Insertar comentario propio" ON task_comments;
DROP POLICY IF EXISTS "Admin ve todas las horas" ON hour_assignments;
DROP POLICY IF EXISTS "Admin gestiona horas" ON hour_assignments;
DROP POLICY IF EXISTS "Ver horas reales propias o admin" ON hour_actuals;
DROP POLICY IF EXISTS "Registrar horas reales propias" ON hour_actuals;
DROP POLICY IF EXISTS "Editar horas reales propias" ON hour_actuals;
DROP POLICY IF EXISTS "Ver capacidad propia o admin" ON user_capacity;
DROP POLICY IF EXISTS "Solo admin modifica capacidad" ON user_capacity;
DROP POLICY IF EXISTS "Ver vacaciones propias o admin" ON vacations;
DROP POLICY IF EXISTS "Registrar vacaciones propias o admin" ON vacations;
DROP POLICY IF EXISTS "Solo gerente elimina vacaciones ajenas" ON vacations;
DROP POLICY IF EXISTS "Ver notas de proyectos propios" ON project_notes;
DROP POLICY IF EXISTS "Cualquiera en el proyecto puede agregar notas" ON project_notes;
DROP POLICY IF EXISTS "Solo admin ve auditoría" ON audit_log;
DROP POLICY IF EXISTS "Sistema inserta en auditoría" ON audit_log;
DROP POLICY IF EXISTS "Tenant profiles policy" ON profiles;
DROP POLICY IF EXISTS "Tenant projects policy" ON projects;
DROP POLICY IF EXISTS "Tenant project_members policy" ON project_members;
DROP POLICY IF EXISTS "Tenant project_stages policy" ON project_stages;
DROP POLICY IF EXISTS "Tenant tasks policy" ON tasks;
DROP POLICY IF EXISTS "Tenant task_comments policy" ON task_comments;
DROP POLICY IF EXISTS "Tenant hour_assignments policy" ON hour_assignments;
DROP POLICY IF EXISTS "Tenant hour_actuals policy" ON hour_actuals;
DROP POLICY IF EXISTS "Tenant user_capacity policy" ON user_capacity;
DROP POLICY IF EXISTS "Tenant vacations policy" ON vacations;
DROP POLICY IF EXISTS "Tenant project_notes policy" ON project_notes;
DROP POLICY IF EXISTS "Tenant audit_log policy" ON audit_log;

CREATE POLICY "Tenant profiles policy" ON profiles FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant projects policy" ON projects FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant project_members policy" ON project_members FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant project_stages policy" ON project_stages FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant tasks policy" ON tasks FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant task_comments policy" ON task_comments FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant hour_assignments policy" ON hour_assignments FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant hour_actuals policy" ON hour_actuals FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant user_capacity policy" ON user_capacity FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant vacations policy" ON vacations FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant project_notes policy" ON project_notes FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());
CREATE POLICY "Tenant audit_log policy" ON audit_log FOR ALL TO authenticated
    USING (tenant_id = public.get_my_tenant_id()) WITH CHECK (tenant_id = public.get_my_tenant_id());

-- ============================================================
-- PASO 8: Trigger para crear perfil automáticamente al registrarse
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_profile_id UUID;
    username_val TEXT;
BEGIN
    new_profile_id := gen_random_uuid();
    username_val := COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1));

    INSERT INTO public.profiles (id, nombre, username, rol, horas_disponibles_default, avatar_color, auth_user_id, tenant_id)
    VALUES (
        new_profile_id,
        COALESCE(new.raw_user_meta_data->>'nombre', split_part(new.email, '@', 1)),
        username_val,
        'gerente',
        160,
        '#3b82f6',
        new.id,
        new_profile_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
