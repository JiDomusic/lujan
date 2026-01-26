-- =============================================
-- SCHEMA COMPLETO PARA PORTFOLIO LUJAN ALLEMAND
-- Copia y pega TODO en Supabase > SQL Editor > Run
-- =============================================

-- Borrar políticas existentes (si existen)
DROP POLICY IF EXISTS "Lectura publica de imagenes" ON gallery_images;
DROP POLICY IF EXISTS "Admin puede insertar imagenes" ON gallery_images;
DROP POLICY IF EXISTS "Admin puede actualizar imagenes" ON gallery_images;
DROP POLICY IF EXISTS "Admin puede eliminar imagenes" ON gallery_images;
DROP POLICY IF EXISTS "Lectura publica de bio" ON bio_content;
DROP POLICY IF EXISTS "Admin puede actualizar bio" ON bio_content;
DROP POLICY IF EXISTS "Lectura publica storage" ON storage.objects;
DROP POLICY IF EXISTS "Admin puede subir" ON storage.objects;
DROP POLICY IF EXISTS "Admin puede actualizar storage" ON storage.objects;
DROP POLICY IF EXISTS "Admin puede eliminar storage" ON storage.objects;

-- Borrar tablas existentes (si existen)
DROP TABLE IF EXISTS gallery_images;
DROP TABLE IF EXISTS bio_content;

-- Crear tabla gallery_images
CREATE TABLE gallery_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  image_url TEXT NOT NULL,
  title TEXT DEFAULT 'Sin titulo',
  technique TEXT DEFAULT 'Oleo sobre lienzo',
  size TEXT NOT NULL,
  year TEXT DEFAULT '',
  rotation INTEGER DEFAULT 0,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear tabla bio_content
CREATE TABLE bio_content (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content_es TEXT NOT NULL,
  content_en TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar bio inicial
INSERT INTO bio_content (content_es, content_en) VALUES (
  'Lujan Allemand nacio en 1983, en Lincoln, Buenos Aires, Argentina. En 2003 se traslado a la ciudad de Rosario, Santa Fe, donde reside actualmente. En 2004 estudio Fotografia en el Iset N 18. Desde 2018 concurre al taller Un triangulo y una calavera, a traves del cual participo en muestras colectivas: Mithila Power, biblioteca La Potencia, 2018; Piedra, Hoja, Rama, Fruto, Caracol, libreria Mal de Archivo, 2019; Banda de Banderas, parque de Las Colectividades, 2019; Artilleria Grafica, Museo Marc, 2020; Friki Flash Tarot, Club 856, 2021; Pua y plumin, Alianza Francesa, 2024. Desde 2019 cursa la carrera Licenciatura en Bellas Artes, en la Universidad Nacional de Rosario. En 2025 fue becaria en la Universidad del Tolima, Colombia.',
  'Lujan Allemand was born in 1983 in Lincoln, Buenos Aires, Argentina. In 2003 she moved to Rosario, Santa Fe, where she currently lives. In 2004 she studied Photography at Iset N 18. Since 2018 she has attended the workshop Un triangulo y una calavera, through which she took part in group shows: Mithila Power, biblioteca La Potencia, 2018; Piedra, Hoja, Rama, Fruto, Caracol, libreria Mal de Archivo, 2019; Banda de Banderas, parque de Las Colectividades, 2019; Artilleria Grafica, Museo Marc, 2020; Friki Flash Tarot, Club 856, 2021; Pua y plumin, Alianza Francesa, 2024. Since 2019 she has been studying for a Bachelor of Fine Arts at the Universidad Nacional de Rosario. In 2025 she was awarded a scholarship at Universidad del Tolima, Colombia.'
);

-- Habilitar RLS
ALTER TABLE gallery_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE bio_content ENABLE ROW LEVEL SECURITY;

-- Políticas para gallery_images
CREATE POLICY "Lectura publica de imagenes" ON gallery_images
  FOR SELECT USING (true);

CREATE POLICY "Admin puede insertar imagenes" ON gallery_images
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin puede actualizar imagenes" ON gallery_images
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Admin puede eliminar imagenes" ON gallery_images
  FOR DELETE USING (auth.role() = 'authenticated');

-- Políticas para bio_content
CREATE POLICY "Lectura publica de bio" ON bio_content
  FOR SELECT USING (true);

CREATE POLICY "Admin puede actualizar bio" ON bio_content
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Políticas para Storage (bucket 'lujan')
CREATE POLICY "Lectura publica storage" ON storage.objects
  FOR SELECT USING (bucket_id = 'lujan');

CREATE POLICY "Admin puede subir" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'lujan' AND auth.role() = 'authenticated');

CREATE POLICY "Admin puede actualizar storage" ON storage.objects
  FOR UPDATE USING (bucket_id = 'lujan' AND auth.role() = 'authenticated');

CREATE POLICY "Admin puede eliminar storage" ON storage.objects
  FOR DELETE USING (bucket_id = 'lujan' AND auth.role() = 'authenticated');
