-- Optional initialization SQL script for MySQL
-- This script creates the `todo_items` table if it doesn’t exist.
CREATE TABLE IF NOT EXISTS todo_items (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  completed BOOLEAN DEFAULT FALSE
);
