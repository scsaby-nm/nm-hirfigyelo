CREATE INDEX IF NOT EXISTS idx_analytics_event_created
ON analytics(event_type, created_at);

CREATE INDEX IF NOT EXISTS idx_analytics_event_article
ON analytics(event_type, article_id);

CREATE TABLE IF NOT EXISTS article_translations (
  article_id TEXT PRIMARY KEY,
  source_text TEXT NOT NULL,
  summary_en TEXT NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

