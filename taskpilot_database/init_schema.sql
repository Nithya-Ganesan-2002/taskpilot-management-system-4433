-- TaskPilot PostgreSQL Initial Schema
-- Supports: User registration/login, tasks, categories, priorities, with all needed constraints and indexes.

-- =================================================================================
-- USERS TABLE
-- =================================================================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =================================================================================
-- PRIORITIES TABLE
-- This is a lookup table for allowed priority levels
-- =================================================================================
CREATE TABLE IF NOT EXISTS priorities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE, -- e.g., Low, Medium, High, Urgent
    sort_order INTEGER NOT NULL DEFAULT 0
);

-- =================================================================================
-- CATEGORIES TABLE
-- Categories are per-user: each user may define their own list.
-- =================================================================================
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    color VARCHAR(20), -- Color code for frontend, optional
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, name) -- Each user may not have duplicate category names
);

-- =================================================================================
-- TASKS TABLE
-- Stores all tasks, linked to user and optionally a category and priority
-- =================================================================================
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    priority_id INTEGER REFERENCES priorities(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    due_date DATE,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- Filtering, association, sorting: via columns/indexes below
    INDEX idx_tasks_user_id (user_id),
    INDEX idx_tasks_category_id (category_id),
    INDEX idx_tasks_priority_id (priority_id),
    INDEX idx_tasks_due_date (due_date),
    INDEX idx_tasks_completed (completed)
);

-- =================================================================================
-- TRIGGERS
-- Automatically update "updated_at" on changes for users and tasks
-- =================================================================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_users_updated_at ON users;
CREATE TRIGGER trg_update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE PROCEDURE update_timestamp();

DROP TRIGGER IF EXISTS trg_update_tasks_updated_at ON tasks;
CREATE TRIGGER trg_update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE PROCEDURE update_timestamp();

-- =================================================================================
-- PREPOPULATE PRIORITIES TABLE
-- =================================================================================
INSERT INTO priorities (name, sort_order)
    VALUES ('Low', 1), ('Medium', 2), ('High', 3), ('Urgent', 4)
    ON CONFLICT (name) DO NOTHING;

-- =================================================================================
-- For filtering and sorting, ensure proper indexes
-- (PostgreSQL automatically indexes primary keys; extra added above)
-- =================================================================================

-- End of schema
