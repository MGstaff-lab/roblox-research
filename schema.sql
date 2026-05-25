-- ============================================================
-- Roblox Research Database Schema
-- Run this first in Supabase SQL Editor
-- ============================================================

-- CHANNELS TABLE
CREATE TABLE IF NOT EXISTS channels (
  id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name                 TEXT NOT NULL,
  url                  TEXT NOT NULL,
  niche                TEXT,
  subscribers          BIGINT,
  date_started         DATE,
  total_videos         INTEGER,
  uploads_per_week     DECIMAL(6,1),
  avg_views_per_video  BIGINT,
  est_monthly_revenue  BIGINT,
  outlier_score        DECIMAL(8,2),
  is_legacy_channel    BOOLEAN DEFAULT FALSE,
  last_scraped_at      TIMESTAMPTZ,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- VIDEOS TABLE
CREATE TABLE IF NOT EXISTS videos (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  channel_id     UUID REFERENCES channels(id) ON DELETE CASCADE,
  channel_name   TEXT,
  niche          TEXT,
  title          TEXT NOT NULL,
  video_id       TEXT UNIQUE,
  url            TEXT,
  views          BIGINT DEFAULT 0,
  published_date DATE,
  thumbnail_url  TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES for fast filtering
CREATE INDEX IF NOT EXISTS idx_channels_niche       ON channels(niche);
CREATE INDEX IF NOT EXISTS idx_channels_subscribers ON channels(subscribers DESC);
CREATE INDEX IF NOT EXISTS idx_videos_channel_id    ON videos(channel_id);
CREATE INDEX IF NOT EXISTS idx_videos_published     ON videos(published_date DESC);
CREATE INDEX IF NOT EXISTS idx_videos_views         ON videos(views DESC);
CREATE INDEX IF NOT EXISTS idx_videos_niche         ON videos(niche);

-- ROW LEVEL SECURITY
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos   ENABLE ROW LEVEL SECURITY;

-- Anyone can read
CREATE POLICY "Public read channels" ON channels FOR SELECT USING (true);
CREATE POLICY "Public read videos"   ON videos   FOR SELECT USING (true);

-- Anyone can insert a channel (for the Add Channel button)
CREATE POLICY "Public insert channels" ON channels FOR INSERT WITH CHECK (true);
