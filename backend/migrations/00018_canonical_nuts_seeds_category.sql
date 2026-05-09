-- Normalize the legacy nuts category to the catalog's canonical nuts-seeds key.

-- +goose Up
UPDATE foods
SET category = 'nuts-seeds'
WHERE category = 'nuts';

-- +goose Down
UPDATE foods
SET category = 'nuts'
WHERE id IN (
    '018f0000-0000-7000-8002-000000000004',
    '018f0000-0000-7000-8002-000000000116',
    '018f0000-0000-7000-8002-000000000117'
);
