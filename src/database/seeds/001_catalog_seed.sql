
BEGIN;

-- 1. Publisher
INSERT INTO publishers (id, name)
VALUES (
    '00000000-0000-4000-8000-000000000003',
    'Prentice Hall'
)
ON CONFLICT (id) DO NOTHING;


-- 2. Author
INSERT INTO authors (id, name)
VALUES (
    '00000000-0000-4000-8000-000000000002',
    'Robert C. Martin'
)
ON CONFLICT (id) DO NOTHING;


-- 3. Book
INSERT INTO books (
    id,
    title,
    description,
    first_publication_year
)
VALUES (
    '00000000-0000-4000-8000-000000000001',
    'Clean Code',
    'A Handbook of Agile Software Craftsmanship.',
    2008
)
ON CONFLICT (id) DO NOTHING;


-- 4. Edition
INSERT INTO editions (
    id,
    book_id,
    publisher_id,
    title,
    isbn_13,
    language_code,
    format
)
VALUES (
    '00000000-0000-4000-8000-000000000004',
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000003',
    'Clean Code',
    '9780132350884',
    'en',
    'Paperback'
)
ON CONFLICT (id) DO NOTHING;


-- 5. Author relationship
INSERT INTO book_authors (book_id, author_id, role)
VALUES (
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000002',
    'author'
)
ON CONFLICT DO NOTHING;


-- 6. Categories
INSERT INTO categories (id, name, slug)
VALUES
(
    '00000000-0000-4000-8000-000000000005',
    'Software Engineering',
    'software-engineering'
),
(
    '00000000-0000-4000-8000-000000000006',
    'Programming',
    'programming'
)
ON CONFLICT (id) DO NOTHING;


-- 7. Book-category relationships
INSERT INTO book_categories (book_id, category_id)
VALUES
(
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000005'
),
(
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000006'
)
ON CONFLICT DO NOTHING;

COMMIT;
