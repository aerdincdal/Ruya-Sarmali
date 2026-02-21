-- =============================================================
-- RÜYA SARMALI - Supabase Database Schema
-- Çalıştırma: Supabase Dashboard → SQL Editor → New Query
-- =============================================================

-- 1. Profiles Tablosu (auth.users ile bağlantılı)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Dreams Tablosu (kullanıcıya bağlı rüyalar)
CREATE TABLE IF NOT EXISTS dreams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prompt TEXT NOT NULL,
  interpretation TEXT,
  celestial_advice TEXT,
  luma_generation_id TEXT,
  video_url TEXT,
  local_filename TEXT,
  resolution TEXT DEFAULT '1080p',
  duration TEXT DEFAULT '9s',
  is_shared BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. İndeksler (performans için)
CREATE INDEX IF NOT EXISTS idx_dreams_user_id ON dreams(user_id);
CREATE INDEX IF NOT EXISTS idx_dreams_created_at ON dreams(created_at DESC);

-- 4. Row Level Security (RLS) Aktifleştirme
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE dreams ENABLE ROW LEVEL SECURITY;

-- 5. Profiles Politikaları
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 6. Dreams Politikaları
CREATE POLICY "Users can view own dreams"
  ON dreams FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own dreams"
  ON dreams FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own dreams"
  ON dreams FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own dreams"
  ON dreams FOR DELETE
  USING (auth.uid() = user_id);

-- 7. Trigger: Yeni kullanıcı kaydında profil oluştur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger'ı bağla
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. Updated_at otomatik güncelleme
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dreams_updated_at
  BEFORE UPDATE ON dreams
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
