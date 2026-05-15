-- ============================================
-- SQL COMPLETO PARA PROYECTO LUJAN - SUPABASE
-- Nuevo proyecto: bcrstbxcheocikcqvvbj
-- ============================================

-- 1. EXTENSIONES
-- ============================================
create extension if not exists "uuid-ossp";

-- 2. FUNCION AUXILIAR: updated_at automático
-- ============================================
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

-- 3. TABLA: gallery_images
-- ============================================
create table if not exists public.gallery_images (
  id uuid default gen_random_uuid() primary key,
  image_url text not null,
  title text default 'Sin titulo',
  technique text default 'Oleo sobre lienzo',
  size text default '',
  year text default '',
  rotation int default 0,
  display_order int default 0,
  created_at timestamptz default now()
);

-- Trigger para updated_at (aunque gallery_images no tiene updated_at,
-- lo dejamos preparado por si en el futuro se agrega)
comment on table public.gallery_images is 'Obras de la galería de Lujan Allemand';

-- 4. TABLA: bio_content
-- ============================================
create table if not exists public.bio_content (
  id uuid default gen_random_uuid() primary key,
  content_es text default '',
  content_en text default '',
  updated_at timestamptz default now()
);

-- Trigger para updated_at automático en bio_content
create trigger bio_content_updated_at
  before update on public.bio_content
  for each row
  execute function public.handle_updated_at();

comment on table public.bio_content is 'Biografía en español e inglés';

-- 5. RLS - ROW LEVEL SECURITY
-- ============================================

-- Habilitar RLS en ambas tablas
alter table public.gallery_images enable row level security;
alter table public.bio_content enable row level security;

-- --------------------------------------------
-- POLICIES: gallery_images
-- --------------------------------------------

-- Cualquiera puede VER las imágenes (lectura pública)
create policy "Galería: lectura pública"
  on public.gallery_images
  for select
  to anon, authenticated
  using (true);

-- Solo lujanporfolio@gmail.com puede INSERTAR
create policy "Galería: insertar solo admin"
  on public.gallery_images
  for insert
  to authenticated
  with check (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- Solo lujanporfolio@gmail.com puede ACTUALIZAR
create policy "Galería: actualizar solo admin"
  on public.gallery_images
  for update
  to authenticated
  using (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com')
  with check (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- Solo lujanporfolio@gmail.com puede ELIMINAR
create policy "Galería: eliminar solo admin"
  on public.gallery_images
  for delete
  to authenticated
  using (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- --------------------------------------------
-- POLICIES: bio_content
-- --------------------------------------------

-- Cualquiera puede VER la biografía (lectura pública)
create policy "Bio: lectura pública"
  on public.bio_content
  for select
  to anon, authenticated
  using (true);

-- Solo lujanporfolio@gmail.com puede INSERTAR
create policy "Bio: insertar solo admin"
  on public.bio_content
  for insert
  to authenticated
  with check (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- Solo lujanporfolio@gmail.com puede ACTUALIZAR
create policy "Bio: actualizar solo admin"
  on public.bio_content
  for update
  to authenticated
  using (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com')
  with check (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- Solo lujanporfolio@gmail.com puede ELIMINAR
create policy "Bio: eliminar solo admin"
  on public.bio_content
  for delete
  to authenticated
  using (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- 6. STORAGE BUCKET
-- ============================================

-- Crear bucket "lujan" si no existe
insert into storage.buckets (id, name, public)
values ('lujan', 'lujan', true)
on conflict (id) do nothing;

-- --------------------------------------------
-- POLICIES: Storage bucket "lujan"
-- --------------------------------------------

-- Cualquiera puede VER/LEER archivos del bucket (imágenes públicas)
create policy "Storage lujan: lectura pública"
  on storage.objects
  for select
  to anon, authenticated
  using (bucket_id = 'lujan');

-- Solo lujanporfolio@gmail.com puede SUBIR archivos
create policy "Storage lujan: subir solo admin"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'lujan' and auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- Solo lujanporfolio@gmail.com puede ACTUALIZAR archivos
create policy "Storage lujan: actualizar solo admin"
  on storage.objects
  for update
  to authenticated
  using (bucket_id = 'lujan' and auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com')
  with check (bucket_id = 'lujan' and auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- Solo lujanporfolio@gmail.com puede ELIMINAR archivos
create policy "Storage lujan: eliminar solo admin"
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'lujan' and auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- 5. TABLA: current_works (Lo que estoy haciendo ahora)
-- ============================================
create table if not exists public.current_works (
  id uuid default gen_random_uuid() primary key,
  title text default '',
  description text default '',
  media_type text not null check (media_type in ('youtube', 'video')),
  media_url text not null,
  display_order int default 0,
  created_at timestamptz default now()
);

comment on table public.current_works is 'Videos y links de YouTube de trabajos en proceso';

-- Habilitar RLS
alter table public.current_works enable row level security;

-- Cualquiera puede VER
create policy "Ahora: lectura pública"
  on public.current_works
  for select
  to anon, authenticated
  using (true);

-- Solo admin puede INSERTAR
create policy "Ahora: insertar solo admin"
  on public.current_works
  for insert
  to authenticated
  with check (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- Solo admin puede ACTUALIZAR
create policy "Ahora: actualizar solo admin"
  on public.current_works
  for update
  to authenticated
  using (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com')
  with check (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- Solo admin puede ELIMINAR
create policy "Ahora: eliminar solo admin"
  on public.current_works
  for delete
  to authenticated
  using (auth.jwt() ->> 'email' = 'lujanporfolio@gmail.com');

-- 7. DATOS INICIALES (opcional)
-- ============================================

-- Insertar un registro vacío de biografía para que la app tenga algo que cargar
insert into public.bio_content (content_es, content_en)
values (
  '[{"insert":"Lujan Allemand nacio en 1983, en Lincoln, Buenos Aires, Argentina. En 2003 se traslado a Rosario, Santa Fe, donde reside actualmente."}]',
  '[{"insert":"Lujan Allemand was born in 1983 in Lincoln, Buenos Aires, Argentina. In 2003 she moved to Rosario, Santa Fe, where she currently lives."}]'
)
on conflict do nothing;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
