CREATE TABLE IF NOT EXISTS nm_articles (
  slug TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  lead TEXT,
  body TEXT NOT NULL,
  image_url TEXT,
  category TEXT,
  source_url TEXT,
  status TEXT NOT NULL DEFAULT 'published',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_nm_articles_status_created
ON nm_articles(status, created_at DESC);
