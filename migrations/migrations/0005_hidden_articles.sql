CREATE TABLE IF NOT EXISTS hidden_articles (
  article_id TEXT PRIMARY KEY,
  title TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

