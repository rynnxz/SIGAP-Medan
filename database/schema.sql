-- MedanHub Database Schema
-- PostgreSQL (Neon)
-- Run this script in your Neon database console

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  google_id VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  avatar_url TEXT,
  total_points INTEGER DEFAULT 0, -- Poin Horas
  current_xp INTEGER DEFAULT 0, -- XP untuk level progression
  level INTEGER DEFAULT 1,
  level_title VARCHAR(100) DEFAULT 'Detektif Kota', -- Badge title (Detektif Kota, Explorer, dll)
  streak_days INTEGER DEFAULT 0, -- Aktif beruntun (hari)
  last_active_date DATE DEFAULT CURRENT_DATE, -- Untuk tracking streak
  total_check_ins INTEGER DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  total_reports INTEGER DEFAULT 0,
  total_upvotes_received INTEGER DEFAULT 0, -- Total upvotes yang diterima user
  bio TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX idx_users_google_id ON users(google_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_points ON users(total_points DESC); -- For leaderboard
CREATE INDEX idx_users_xp ON users(current_xp DESC);

-- ============================================
-- DESTINATIONS TABLE
-- ============================================
CREATE TABLE destinations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  category VARCHAR(50) NOT NULL, -- 'landmark', 'culinary', 'nature', 'culture'
  description TEXT,
  address TEXT,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  image_url TEXT, -- Cloudinary URL
  gallery_urls TEXT[], -- Array of image URLs
  rating DECIMAL(2, 1) DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  total_likes INTEGER DEFAULT 0, -- Total likes/favorites
  total_check_ins INTEGER DEFAULT 0, -- Total check-ins
  points_reward INTEGER DEFAULT 10,
  xp_reward INTEGER DEFAULT 50, -- XP yang didapat saat check-in
  opening_hours JSONB, -- {"monday": "08:00-17:00", ...}
  facilities TEXT[], -- ["parking", "toilet", "wifi"]
  ticket_price VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_destinations_category ON destinations(category);
CREATE INDEX idx_destinations_location ON destinations(latitude, longitude);
CREATE INDEX idx_destinations_rating ON destinations(rating DESC);
CREATE INDEX idx_destinations_likes ON destinations(total_likes DESC); -- For popular destinations

-- ============================================
-- CHECK-INS TABLE
-- ============================================
CREATE TABLE check_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  destination_id UUID REFERENCES destinations(id) ON DELETE CASCADE,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  points_earned INTEGER DEFAULT 10,
  photo_url TEXT, -- Optional check-in photo (Cloudinary)
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Unique constraint: 1 check-in per user per destination per day
CREATE UNIQUE INDEX idx_unique_daily_checkin 
ON check_ins(user_id, destination_id, DATE(created_at));

-- Indexes
CREATE INDEX idx_checkins_user ON check_ins(user_id);
CREATE INDEX idx_checkins_destination ON check_ins(destination_id);
CREATE INDEX idx_checkins_date ON check_ins(created_at DESC);

-- ============================================
-- REVIEWS TABLE
-- ============================================
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  destination_id UUID REFERENCES destinations(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
  comment TEXT,
  photos TEXT[], -- Array of photo URLs
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Unique constraint: 1 review per user per destination
CREATE UNIQUE INDEX idx_unique_user_review 
ON reviews(user_id, destination_id);

-- Indexes
CREATE INDEX idx_reviews_destination ON reviews(destination_id);
CREATE INDEX idx_reviews_rating ON reviews(rating DESC);

-- ============================================
-- REPORTS TABLE
-- ============================================
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  destination_id UUID REFERENCES destinations(id) ON DELETE SET NULL,
  category VARCHAR(50) NOT NULL, -- 'damage', 'cleanliness', 'safety', 'accessibility', 'other'
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  photo_url TEXT, -- Cloudinary URL
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'reviewed', 'resolved', 'rejected'
  total_upvotes INTEGER DEFAULT 0, -- Total upvotes untuk report
  admin_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_reports_user ON reports(user_id);
CREATE INDEX idx_reports_destination ON reports(destination_id);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_date ON reports(created_at DESC);
CREATE INDEX idx_reports_upvotes ON reports(total_upvotes DESC); -- For trending reports

-- ============================================
-- ACHIEVEMENTS TABLE
-- ============================================
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  achievement_type VARCHAR(50) NOT NULL, -- 'first_checkin', 'explorer_5', 'reviewer', 'reporter', etc.
  title VARCHAR(255) NOT NULL,
  description TEXT,
  icon_url TEXT,
  points_awarded INTEGER DEFAULT 0,
  earned_at TIMESTAMP DEFAULT NOW()
);

-- Unique constraint: 1 achievement type per user
CREATE UNIQUE INDEX idx_unique_user_achievement 
ON achievements(user_id, achievement_type);

-- Index
CREATE INDEX idx_achievements_user ON achievements(user_id);

-- ============================================
-- POINTS HISTORY TABLE
-- ============================================
CREATE TABLE points_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  points INTEGER NOT NULL, -- Can be positive or negative
  xp INTEGER DEFAULT 0, -- XP yang didapat bersamaan dengan points
  source VARCHAR(50) NOT NULL, -- 'checkin', 'review', 'report', 'achievement', 'admin'
  source_id UUID, -- Reference to check_in, review, report, or achievement
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Index
CREATE INDEX idx_points_history_user ON points_history(user_id);
CREATE INDEX idx_points_history_date ON points_history(created_at DESC);

-- ============================================
-- LIKES TABLE (For Destinations & Reports)
-- ============================================
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  target_type VARCHAR(20) NOT NULL, -- 'destination' or 'report'
  target_id UUID NOT NULL, -- ID of destination or report
  created_at TIMESTAMP DEFAULT NOW()
);

-- Unique constraint: 1 like per user per target
CREATE UNIQUE INDEX idx_unique_user_like 
ON likes(user_id, target_type, target_id);

-- Indexes
CREATE INDEX idx_likes_user ON likes(user_id);
CREATE INDEX idx_likes_target ON likes(target_type, target_id);

-- ============================================
-- FAVORITES TABLE (Bookmark Destinations)
-- ============================================
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  destination_id UUID REFERENCES destinations(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Unique constraint: 1 favorite per user per destination
CREATE UNIQUE INDEX idx_unique_user_favorite 
ON favorites(user_id, destination_id);

-- Indexes
CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_destination ON favorites(destination_id);

-- ============================================
-- COMMENTS TABLE (For Destinations & Reports)
-- ============================================
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  target_type VARCHAR(20) NOT NULL, -- 'destination' or 'report'
  target_id UUID NOT NULL, -- ID of destination or report
  comment TEXT NOT NULL,
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE, -- For nested replies
  total_likes INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_target ON comments(target_type, target_id);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id);
CREATE INDEX idx_comments_date ON comments(created_at DESC);

-- ============================================
-- COMMENT LIKES TABLE
-- ============================================
CREATE TABLE comment_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Unique constraint: 1 like per user per comment
CREATE UNIQUE INDEX idx_unique_user_comment_like 
ON comment_likes(user_id, comment_id);

-- Indexes
CREATE INDEX idx_comment_likes_user ON comment_likes(user_id);
CREATE INDEX idx_comment_likes_comment ON comment_likes(comment_id);

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger: Update user total_points and current_xp when points_history is added
CREATE OR REPLACE FUNCTION update_user_points_and_xp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users 
  SET total_points = total_points + NEW.points,
      current_xp = current_xp + COALESCE(NEW.xp, 0),
      updated_at = NOW()
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_points_xp
AFTER INSERT ON points_history
FOR EACH ROW
EXECUTE FUNCTION update_user_points_and_xp();

-- Trigger: Update destination stats when like is added/removed
CREATE OR REPLACE FUNCTION update_destination_likes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.target_type = 'destination' THEN
    UPDATE destinations
    SET total_likes = total_likes + 1,
        updated_at = NOW()
    WHERE id = NEW.target_id;
  ELSIF TG_OP = 'DELETE' AND OLD.target_type = 'destination' THEN
    UPDATE destinations
    SET total_likes = GREATEST(total_likes - 1, 0),
        updated_at = NOW()
    WHERE id = OLD.target_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_destination_likes_insert
AFTER INSERT ON likes
FOR EACH ROW
EXECUTE FUNCTION update_destination_likes();

CREATE TRIGGER trigger_destination_likes_delete
AFTER DELETE ON likes
FOR EACH ROW
EXECUTE FUNCTION update_destination_likes();

-- Trigger: Update report upvotes when like is added/removed
CREATE OR REPLACE FUNCTION update_report_upvotes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.target_type = 'report' THEN
    UPDATE reports
    SET total_upvotes = total_upvotes + 1,
        updated_at = NOW()
    WHERE id = NEW.target_id;
    
    -- Update user's total_upvotes_received
    UPDATE users
    SET total_upvotes_received = total_upvotes_received + 1,
        updated_at = NOW()
    WHERE id = (SELECT user_id FROM reports WHERE id = NEW.target_id);
        
  ELSIF TG_OP = 'DELETE' AND OLD.target_type = 'report' THEN
    UPDATE reports
    SET total_upvotes = GREATEST(total_upvotes - 1, 0),
        updated_at = NOW()
    WHERE id = OLD.target_id;
    
    -- Update user's total_upvotes_received
    UPDATE users
    SET total_upvotes_received = GREATEST(total_upvotes_received - 1, 0),
        updated_at = NOW()
    WHERE id = (SELECT user_id FROM reports WHERE id = OLD.target_id);
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_report_upvotes_insert
AFTER INSERT ON likes
FOR EACH ROW
EXECUTE FUNCTION update_report_upvotes();

CREATE TRIGGER trigger_report_upvotes_delete
AFTER DELETE ON likes
FOR EACH ROW
EXECUTE FUNCTION update_report_upvotes();

-- Trigger: Update comment likes count
CREATE OR REPLACE FUNCTION update_comment_likes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE comments
    SET total_likes = total_likes + 1,
        updated_at = NOW()
    WHERE id = NEW.comment_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE comments
    SET total_likes = GREATEST(total_likes - 1, 0),
        updated_at = NOW()
    WHERE id = OLD.comment_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_comment_likes_insert
AFTER INSERT ON comment_likes
FOR EACH ROW
EXECUTE FUNCTION update_comment_likes();

CREATE TRIGGER trigger_comment_likes_delete
AFTER DELETE ON comment_likes
FOR EACH ROW
EXECUTE FUNCTION update_comment_likes();

-- Trigger: Update user stats when check-in is created
CREATE OR REPLACE FUNCTION update_user_checkin_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET total_check_ins = total_check_ins + 1,
      updated_at = NOW()
  WHERE id = NEW.user_id;
  
  UPDATE destinations
  SET total_check_ins = total_check_ins + 1,
      updated_at = NOW()
  WHERE id = NEW.destination_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_checkin_stats
AFTER INSERT ON check_ins
FOR EACH ROW
EXECUTE FUNCTION update_user_checkin_stats();

-- Trigger: Update user stats when review is created
CREATE OR REPLACE FUNCTION update_user_review_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET total_reviews = total_reviews + 1,
      updated_at = NOW()
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_review_stats
AFTER INSERT ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_user_review_stats();

-- Trigger: Update user stats when report is created
CREATE OR REPLACE FUNCTION update_user_report_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET total_reports = total_reports + 1,
      updated_at = NOW()
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_report_stats
AFTER INSERT ON reports
FOR EACH ROW
EXECUTE FUNCTION update_user_report_stats();

-- Trigger: Update user streak when active
CREATE OR REPLACE FUNCTION update_user_streak()
RETURNS TRIGGER AS $$
DECLARE
  days_diff INTEGER;
BEGIN
  -- Calculate days difference
  days_diff := CURRENT_DATE - OLD.last_active_date;
  
  IF days_diff = 1 THEN
    -- Consecutive day: increment streak
    NEW.streak_days := OLD.streak_days + 1;
  ELSIF days_diff > 1 THEN
    -- Streak broken: reset to 1
    NEW.streak_days := 1;
  END IF;
  
  -- Update last active date
  NEW.last_active_date := CURRENT_DATE;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_streak
BEFORE UPDATE ON users
FOR EACH ROW
WHEN (NEW.last_active_date != OLD.last_active_date)
EXECUTE FUNCTION update_user_streak();

-- Trigger: Update destination rating when review is added/updated/deleted
CREATE OR REPLACE FUNCTION update_destination_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE destinations
  SET 
    rating = (SELECT COALESCE(AVG(rating), 0) FROM reviews WHERE destination_id = COALESCE(NEW.destination_id, OLD.destination_id)),
    total_reviews = (SELECT COUNT(*) FROM reviews WHERE destination_id = COALESCE(NEW.destination_id, OLD.destination_id)),
    updated_at = NOW()
  WHERE id = COALESCE(NEW.destination_id, OLD.destination_id);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_destination_rating_insert
AFTER INSERT ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_destination_rating();

CREATE TRIGGER trigger_update_destination_rating_update
AFTER UPDATE ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_destination_rating();

CREATE TRIGGER trigger_update_destination_rating_delete
AFTER DELETE ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_destination_rating();

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_destinations_updated_at
BEFORE UPDATE ON destinations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_reviews_updated_at
BEFORE UPDATE ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_reports_updated_at
BEFORE UPDATE ON reports
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Insert sample destination (Merdeka Walk)
INSERT INTO destinations (name, category, description, address, latitude, longitude, image_url, points_reward)
VALUES (
  'Merdeka Walk',
  'landmark',
  'Kawasan bersejarah di pusat kota Medan dengan berbagai bangunan kolonial dan area pejalan kaki yang nyaman.',
  'Jl. Balai Kota, Kesawan, Medan Barat, Kota Medan',
  3.5952,
  98.6722,
  'https://res.cloudinary.com/demo/image/upload/sample.jpg',
  15
);

-- Insert sample destination (Tjong A Fie Mansion)
INSERT INTO destinations (name, category, description, address, latitude, longitude, image_url, points_reward)
VALUES (
  'Tjong A Fie Mansion',
  'culture',
  'Rumah bersejarah milik pengusaha Tionghoa terkenal Tjong A Fie, menampilkan arsitektur kolonial yang indah.',
  'Jl. Jend. Ahmad Yani No.105, Kesawan, Medan Barat',
  3.5889,
  98.6819,
  'https://res.cloudinary.com/demo/image/upload/sample.jpg',
  20
);

-- Note: Replace image URLs with actual Cloudinary URLs after upload
