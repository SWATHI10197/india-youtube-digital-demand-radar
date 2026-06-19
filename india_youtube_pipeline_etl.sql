CREATE DATABASE in_youtube_analytics;
USE in_youtube_analytics;

-- 1. Create Lookup Dimension Table
CREATE TABLE dim_categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100)
);

-- Populate categories from the dataset mapping JSON file
INSERT INTO dim_categories (category_id, category_name) VALUES
(1, 'Film & Animation'), (2, 'Autos & Vehicles'), (10, 'Music'), (15, 'Pets & Animals'),
(17, 'Sports'), (20, 'Gaming'), (22, 'People & Blogs'), (23, 'Comedy'), 
(24, 'Entertainment'), (25, 'News & Politics'), (26, 'Howto & Style'), (27, 'Education');

-- 2. Create Core Fact Table to host the IN_youtube_trending_data.csv records
CREATE TABLE fact_in_trending (
    video_id VARCHAR(50),
    title VARCHAR(255),
    publishedAt VARCHAR(100), -- Kept text initially to handle timezone scrubbing
    channelId VARCHAR(50),
    channelTitle VARCHAR(255),
    category_id INT,
    trending_date VARCHAR(50), -- Kept text initially for structural casting
    view_count BIGINT,
    likes BIGINT,
    dislikes BIGINT,
    comment_count BIGINT,
    thumbnail_link VARCHAR(255),
    comments_disabled BOOLEAN,
    ratings_disabled BOOLEAN,
    description TEXT
);

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'F:/Swathi/Pject/Live Pject/IN_youtube_trending_data.csv'
INTO TABLE fact_in_trending
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

USE in_youtube_analytics;

-- Drop your old structure completely
DROP TABLE IF EXISTS fact_in_trending;

-- Recreate with the exact structure of the file
CREATE TABLE fact_in_trending (
    video_id VARCHAR(50),
    title VARCHAR(255),
    publishedAt VARCHAR(100),
    channelId VARCHAR(50),
    channelTitle VARCHAR(255),
    category_id INT,
    trending_date VARCHAR(50),
    tags TEXT,                     -- This field was missing, causing columns to shift!
    view_count BIGINT,
    likes BIGINT,
    dislikes BIGINT,
    comment_count BIGINT,
    thumbnail_link VARCHAR(255),
    comments_disabled VARCHAR(10),  -- Changed to text to handle 'True'/'False' safely
    ratings_disabled VARCHAR(10),   -- Changed to text to handle 'True'/'False' safely
    description TEXT
);

SELECT 
    COUNT(*) AS total_records,
    ROUND(AVG(view_count), 0) AS average_views,
    MAX(view_count) AS maximum_views
FROM fact_in_trending;

CREATE OR REPLACE VIEW view_pbi_india_engagement AS
SELECT 
    f.video_id AS VideoID,
    f.channelTitle AS ChannelTitle,
    c.category_name AS CategoryName,
    -- Safely converts the string format (e.g., '2020-08-12T00:00:00Z') to an operational Date
    STR_TO_DATE(SUBSTRING(f.trending_date, 1, 10), '%Y-%m-%d') AS TrendingDate,
    f.view_count AS DailyViews,
    f.likes AS DailyLikes,
    f.comment_count AS DailyComments,
    -- KPI: Engagement metrics standardized per 100 views
    ROUND(((f.likes + f.comment_count) / f.view_count) * 100, 2) AS EngagementRate
FROM fact_in_trending f
INNER JOIN dim_categories c ON f.category_id = c.category_id
WHERE f.view_count > 0;
