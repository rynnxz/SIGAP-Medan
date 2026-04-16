-- Sample Destinations Data for MedanHub
-- Run this after schema.sql to populate with Medan tourism data
-- Replace image URLs with actual Cloudinary URLs after upload

-- ============================================
-- LANDMARKS
-- ============================================

INSERT INTO destinations (name, category, description, address, latitude, longitude, points_reward, xp_reward, ticket_price, facilities) VALUES
('Merdeka Walk', 'landmark', 'Kawasan bersejarah di pusat kota Medan dengan berbagai bangunan kolonial dan area pejalan kaki yang nyaman. Tempat favorit untuk berfoto dan menikmati suasana kota tua.', 'Jl. Balai Kota, Kesawan, Medan Barat, Kota Medan', 3.5952, 98.6722, 15, 50, 'Gratis', ARRAY['parking', 'toilet', 'wifi', 'photo_spot']),

('Tjong A Fie Mansion', 'landmark', 'Rumah bersejarah milik pengusaha Tionghoa terkenal Tjong A Fie. Menampilkan arsitektur kolonial yang indah dengan koleksi antik dan furniture asli dari era 1900-an.', 'Jl. Jend. Ahmad Yani No.105, Kesawan, Medan Barat', 3.5889, 98.6819, 20, 75, 'Rp 25.000', ARRAY['parking', 'toilet', 'guide', 'photo_spot']),

('Istana Maimun', 'landmark', 'Istana kerajaan Kesultanan Deli yang dibangun tahun 1888. Arsitektur Melayu dengan pengaruh Islam, Spanyol, India, dan Italia. Masih digunakan untuk upacara adat.', 'Jl. Brigadir Jenderal Katamso No.5, Sukaraja, Medan Maimun', 3.5752, 98.6837, 20, 75, 'Rp 10.000', ARRAY['parking', 'toilet', 'guide', 'photo_spot', 'souvenir']),

('Masjid Raya Al-Mashun', 'landmark', 'Masjid megah bergaya Timur Tengah yang dibangun tahun 1906. Terletak bersebelahan dengan Istana Maimun. Arsitektur yang memukau dengan kubah besar dan menara tinggi.', 'Jl. Sisingamangaraja, Aur, Medan Maimun', 3.5745, 98.6825, 15, 50, 'Gratis', ARRAY['parking', 'toilet', 'prayer_room']),

('Vihara Gunung Timur', 'landmark', 'Vihara tertua di Medan yang dibangun tahun 1890-an. Arsitektur Tionghoa klasik dengan ornamen naga dan patung dewa. Tempat ibadah yang masih aktif hingga kini.', 'Jl. Hang Tuah No.2, Madras Hulu, Medan Polonia', 3.5834, 98.6789, 15, 50, 'Gratis', ARRAY['parking', 'prayer_room', 'photo_spot']),

('Taman Berastagi (Lapangan Merdeka)', 'landmark', 'Taman kota bersejarah di pusat Medan. Tempat berkumpul warga dengan air mancur dan area hijau. Dikelilingi bangunan kolonial bersejarah.', 'Jl. Balai Kota, Petisah Tengah, Medan Petisah', 3.5889, 98.6722, 10, 30, 'Gratis', ARRAY['parking', 'toilet', 'playground', 'jogging_track']),

('Kantor Pos Besar Medan', 'landmark', 'Bangunan pos bersejarah bergaya Art Deco yang dibangun tahun 1911. Masih beroperasi sebagai kantor pos dengan arsitektur kolonial yang terawat.', 'Jl. Balai Kota No.1, Kesawan, Medan Barat', 3.5889, 98.6728, 10, 30, 'Gratis', ARRAY['parking', 'toilet', 'photo_spot']);

-- ============================================
-- CULINARY
-- ============================================

INSERT INTO destinations (name, category, description, address, latitude, longitude, points_reward, xp_reward, ticket_price, facilities) VALUES
('Soto Kesawan', 'culinary', 'Warung soto legendaris di kawasan Kesawan. Terkenal dengan soto ayam khas Medan yang gurih dengan kuah bening dan bumbu rempah yang khas. Sudah berdiri sejak puluhan tahun.', 'Jl. S. Parman No.240, Kesawan, Medan Barat', 3.5912, 98.6745, 10, 30, 'Rp 15.000 - 30.000', ARRAY['parking', 'toilet', 'halal']),

('Tip Top Restaurant', 'culinary', 'Restoran legendaris sejak 1934 dengan nuansa kolonial. Menu favorit: Nasi Goreng Tip Top, Ice Cream, dan Roti Bakar. Tempat bersejarah yang wajib dikunjungi.', 'Jl. Jend. Ahmad Yani No.92, Kesawan, Medan Barat', 3.5889, 98.6812, 15, 50, 'Rp 30.000 - 100.000', ARRAY['parking', 'toilet', 'wifi', 'ac']),

('Bika Ambon Zulaikha', 'culinary', 'Toko bika ambon terkenal di Medan. Bika ambon lembut dengan berbagai varian rasa: original, pandan, durian, keju. Oleh-oleh khas Medan yang wajib dibawa pulang.', 'Jl. Mojopahit No.10, Petisah Tengah, Medan Petisah', 3.5867, 98.6734, 10, 30, 'Rp 50.000 - 150.000/box', ARRAY['parking', 'ac', 'halal']),

('Mie Balap Medan', 'culinary', 'Mie khas Medan dengan kuah kaldu ayam yang gurih. Topping ayam suwir, pangsit goreng, dan sayuran. Porsi besar dengan harga terjangkau.', 'Jl. Semarang No.1, Madras Hulu, Medan Polonia', 3.5823, 98.6756, 10, 30, 'Rp 20.000 - 35.000', ARRAY['parking', 'halal']),

('Durian Ucok', 'culinary', 'Tempat makan durian legendaris di Medan. Durian segar berkualitas dengan berbagai jenis: Medan, Monthong, Musang King. Buka hingga larut malam.', 'Jl. Mojopahit No.77, Petisah Tengah, Medan Petisah', 3.5845, 98.6723, 15, 50, 'Rp 30.000 - 200.000/kg', ARRAY['parking', 'toilet']),

('Sate Padang Ajo Ramon', 'culinary', 'Sate Padang dengan kuah kental khas Padang. Daging empuk dengan bumbu rempah yang kaya. Salah satu sate Padang terenak di Medan.', 'Jl. Gajah Mada No.88, Petisah Tengah, Medan Petisah', 3.5878, 98.6745, 10, 30, 'Rp 25.000 - 50.000', ARRAY['parking', 'halal']);

-- ============================================
-- NATURE
-- ============================================

INSERT INTO destinations (name, category, description, address, latitude, longitude, points_reward, ticket_price, facilities) VALUES
('Taman Cadika', 'nature', 'Taman kota dengan danau buatan dan area hijau yang luas. Tempat favorit untuk jogging, bersepeda, dan piknik keluarga. Ada area bermain anak dan spot foto instagramable.', 'Jl. Gatot Subroto, Sei Sikambing D, Medan Sunggal', 3.6123, 98.6534, 10, 'Gratis', ARRAY['parking', 'toilet', 'playground', 'jogging_track', 'photo_spot']),

('Taman Simalem Resort (View Point)', 'nature', 'Resort dengan pemandangan Danau Toba yang spektakuler. Udara sejuk pegunungan, kebun teh, dan berbagai aktivitas outdoor. Cocok untuk weekend getaway.', 'Merek, Karo Regency (2 jam dari Medan)', 3.1234, 98.4567, 25, 'Rp 50.000 (entrance)', ARRAY['parking', 'toilet', 'restaurant', 'photo_spot', 'camping']),

('Taman Hutan Raya Bukit Barisan', 'nature', 'Hutan kota dengan area hijau yang luas. Cocok untuk hiking, bird watching, dan menikmati alam. Ada jalur trekking dan spot camping.', 'Jl. Bukit Barisan, Sibolangit, Deli Serdang', 3.4567, 98.5678, 15, 'Rp 5.000', ARRAY['parking', 'toilet', 'camping', 'hiking_trail']),

('Pantai Cermin', 'nature', 'Pantai dengan pasir putih dan air jernih. Berbagai wahana permainan air dan spot foto. Cocok untuk liburan keluarga. Sekitar 1 jam dari pusat kota Medan.', 'Pantai Cermin, Langkat Regency', 3.7234, 98.8456, 20, 'Rp 10.000', ARRAY['parking', 'toilet', 'restaurant', 'photo_spot', 'swimming']);

-- ============================================
-- CULTURE
-- ============================================

INSERT INTO destinations (name, category, description, address, latitude, longitude, points_reward, ticket_price, facilities) VALUES
('Museum Negeri Sumatera Utara', 'culture', 'Museum dengan koleksi benda bersejarah dan budaya Sumatera Utara. Replika rumah adat Batak, Melayu, dan Nias. Koleksi artefak, senjata tradisional, dan tekstil.', 'Jl. H.M. Joni No.51, Sikambing, Medan Sunggal', 3.6012, 98.6589, 15, 'Rp 5.000', ARRAY['parking', 'toilet', 'guide', 'photo_spot']),

('Rumah Tjong A Fie', 'culture', 'Rumah bersejarah dengan arsitektur perpaduan Tionghoa dan Eropa. Museum yang menampilkan kehidupan keluarga Tjong A Fie dengan furniture dan barang antik asli.', 'Jl. Jend. Ahmad Yani No.105, Kesawan, Medan Barat', 3.5889, 98.6819, 20, 'Rp 25.000', ARRAY['parking', 'toilet', 'guide', 'photo_spot', 'ac']),

('Kampung Keling (Little India)', 'culture', 'Kawasan dengan nuansa India yang kental. Banyak toko kain, restoran India, dan kuil Hindu. Tempat yang colorful dan instagramable.', 'Jl. Kampung Keling, Madras Hulu, Medan Polonia', 3.5834, 98.6778, 10, 'Gratis', ARRAY['parking', 'photo_spot', 'shopping']),

('Kuil Shri Mariamman', 'culture', 'Kuil Hindu tertua di Medan yang dibangun tahun 1884. Arsitektur Dravidian dengan gopuram (menara) yang indah. Tempat ibadah yang masih aktif.', 'Jl. Teuku Umar No.14, Madras Hulu, Medan Polonia', 3.5823, 98.6789, 15, 'Gratis', ARRAY['parking', 'prayer_room', 'photo_spot']),

('Pasar Rame (Chinatown)', 'culture', 'Kawasan Chinatown dengan bangunan toko bergaya Tionghoa. Pusat perdagangan dengan berbagai toko, restoran, dan vihara. Ramai terutama saat perayaan Imlek.', 'Jl. Pasar Rame, Kesawan, Medan Barat', 3.5912, 98.6756, 10, 'Gratis', ARRAY['parking', 'shopping', 'photo_spot']);

-- ============================================
-- Update opening hours for some destinations
-- ============================================

UPDATE destinations SET opening_hours = '{
  "monday": "08:00-17:00",
  "tuesday": "08:00-17:00",
  "wednesday": "08:00-17:00",
  "thursday": "08:00-17:00",
  "friday": "08:00-17:00",
  "saturday": "08:00-17:00",
  "sunday": "08:00-17:00"
}'::jsonb WHERE name IN ('Tjong A Fie Mansion', 'Istana Maimun', 'Museum Negeri Sumatera Utara');

UPDATE destinations SET opening_hours = '{
  "monday": "24 hours",
  "tuesday": "24 hours",
  "wednesday": "24 hours",
  "thursday": "24 hours",
  "friday": "24 hours",
  "saturday": "24 hours",
  "sunday": "24 hours"
}'::jsonb WHERE name IN ('Merdeka Walk', 'Taman Berastagi (Lapangan Merdeka)', 'Kampung Keling (Little India)');

UPDATE destinations SET opening_hours = '{
  "monday": "10:00-22:00",
  "tuesday": "10:00-22:00",
  "wednesday": "10:00-22:00",
  "thursday": "10:00-22:00",
  "friday": "10:00-22:00",
  "saturday": "10:00-23:00",
  "sunday": "10:00-23:00"
}'::jsonb WHERE category = 'culinary';

-- ============================================
-- Verify data
-- ============================================

-- Count destinations by category
SELECT category, COUNT(*) as total 
FROM destinations 
GROUP BY category 
ORDER BY category;

-- Show all destinations
SELECT name, category, address, points_reward, ticket_price 
FROM destinations 
ORDER BY category, name;

