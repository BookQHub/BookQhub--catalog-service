
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==========================================
-- 1. BOOKS
-- Represents intellectual works
-- ==========================================

CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    title VARCHAR(500) NOT NULL,
    description TEXT,
    first_publication_year INTEGER,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT books_title_not_empty
        CHECK (LENGTH(TRIM(title)) > 0),

    CONSTRAINT books_publication_year_valid
        CHECK (
            first_publication_year IS NULL
            OR first_publication_year BETWEEN 1 AND 9999
        )
);

CREATE INDEX idx_books_active_title
    ON books(title)
    WHERE deleted_at IS NULL;


-- ==========================================
-- 2. AUTHORS
-- ==========================================

CREATE TABLE authors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(255) NOT NULL,
    biography TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT authors_name_not_empty
        CHECK (LENGTH(TRIM(name)) > 0)
);

CREATE INDEX idx_authors_active_name
    ON authors(name)
    WHERE deleted_at IS NULL;


-- ==========================================
-- 3. BOOK-AUTHOR RELATIONSHIP
-- Many-to-many
-- ==========================================

CREATE TABLE book_authors (
    book_id UUID NOT NULL
        REFERENCES books(id) ON DELETE RESTRICT,

    author_id UUID NOT NULL
        REFERENCES authors(id) ON DELETE RESTRICT,

    role VARCHAR(50) NOT NULL DEFAULT 'author',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (book_id, author_id, role),

    CONSTRAINT book_authors_role_not_empty
        CHECK (LENGTH(TRIM(role)) > 0)
);

CREATE INDEX idx_book_authors_author_id
    ON book_authors(author_id);


-- ==========================================
-- 4. PUBLISHERS
-- ==========================================

CREATE TABLE publishers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(255) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT publishers_name_not_empty
        CHECK (LENGTH(TRIM(name)) > 0)
);

CREATE INDEX idx_publishers_active_name
    ON publishers(name)
    WHERE deleted_at IS NULL;


-- ==========================================
-- 5. EDITIONS
-- A specific published version of a book
-- ==========================================

CREATE TABLE editions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL
        REFERENCES books(id) ON DELETE RESTRICT,

    publisher_id UUID
        REFERENCES publishers(id) ON DELETE RESTRICT,

    title VARCHAR(500),

    isbn_10 VARCHAR(10),
    isbn_13 VARCHAR(13),

    language_code VARCHAR(10),
    publication_date DATE,
    page_count INTEGER,

    format VARCHAR(50),
    cover_url TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT editions_page_count_positive
        CHECK (page_count IS NULL OR page_count > 0),

    CONSTRAINT editions_isbn_10_length
        CHECK (
            isbn_10 IS NULL OR
            isbn_10 ~ '^[0-9]{9}[0-9X]$'
        ),

    CONSTRAINT editions_isbn_13_length
        CHECK (
            isbn_13 IS NULL OR
            isbn_13 ~ '^[0-9]{13}$'
        )
);

CREATE UNIQUE INDEX editions_active_isbn_10_unique
    ON editions(isbn_10)
    WHERE isbn_10 IS NOT NULL
      AND deleted_at IS NULL;

CREATE UNIQUE INDEX editions_active_isbn_13_unique
    ON editions(isbn_13)
    WHERE isbn_13 IS NOT NULL
      AND deleted_at IS NULL;

CREATE INDEX idx_editions_active_book_id
    ON editions(book_id)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_editions_publisher_id
    ON editions(publisher_id)
    WHERE deleted_at IS NULL;


-- ==========================================
-- 6. CATEGORIES
-- Hierarchical classification
-- ==========================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    parent_id UUID
        REFERENCES categories(id) ON DELETE RESTRICT,

    name VARCHAR(150) NOT NULL,
    slug VARCHAR(180) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT categories_name_not_empty
        CHECK (LENGTH(TRIM(name)) > 0),

    CONSTRAINT categories_slug_not_empty
        CHECK (LENGTH(TRIM(slug)) > 0),

    CONSTRAINT categories_cannot_be_own_parent
        CHECK (parent_id IS NULL OR parent_id <> id)
);

CREATE UNIQUE INDEX categories_active_slug_unique
    ON categories(slug)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_categories_parent_id
    ON categories(parent_id);


-- ==========================================
-- 7. BOOK-CATEGORY RELATIONSHIP
-- Many-to-many
-- ==========================================

CREATE TABLE book_categories (
    book_id UUID NOT NULL
        REFERENCES books(id) ON DELETE RESTRICT,

    category_id UUID NOT NULL
        REFERENCES categories(id) ON DELETE RESTRICT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (book_id, category_id)
);

CREATE INDEX idx_book_categories_category_id
    ON book_categories(category_id);


-- ==========================================
-- 8. EXTERNAL IDENTIFIERS
-- Maps internal records to external providers
-- ==========================================

CREATE TABLE book_external_ids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL
        REFERENCES books(id) ON DELETE RESTRICT,

    provider VARCHAR(50) NOT NULL,
    external_id VARCHAR(255) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT book_external_ids_provider_id_unique
        UNIQUE (provider, external_id),

    CONSTRAINT book_external_ids_not_empty
        CHECK (
            LENGTH(TRIM(provider)) > 0
            AND LENGTH(TRIM(external_id)) > 0
        ),

    CONSTRAINT book_external_ids_book_provider_unique
        UNIQUE (book_id, provider)
);

CREATE TABLE author_external_ids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    author_id UUID NOT NULL
        REFERENCES authors(id) ON DELETE RESTRICT,

    provider VARCHAR(50) NOT NULL,
    external_id VARCHAR(255) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT author_external_ids_provider_id_unique
        UNIQUE (provider, external_id),

    CONSTRAINT author_external_ids_author_provider_unique
        UNIQUE (author_id, provider)
);

CREATE TABLE edition_external_ids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    edition_id UUID NOT NULL
        REFERENCES editions(id) ON DELETE RESTRICT,

    provider VARCHAR(50) NOT NULL,
    external_id VARCHAR(255) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT edition_external_ids_provider_id_unique
        UNIQUE (provider, external_id),

    CONSTRAINT edition_external_ids_edition_provider_unique
        UNIQUE (edition_id, provider)
);


-- ==========================================
-- 9. UPDATED_AT AUTOMATIC MAINTENANCE
-- ==========================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER books_updated_at
BEFORE UPDATE ON books
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER authors_updated_at
BEFORE UPDATE ON authors
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER publishers_updated_at
BEFORE UPDATE ON publishers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER editions_updated_at
BEFORE UPDATE ON editions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
