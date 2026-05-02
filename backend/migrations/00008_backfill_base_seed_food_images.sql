-- +goose Up
UPDATE foods
SET image_url = CASE id
    WHEN '018f0000-0000-7000-8002-000000000001'::uuid THEN 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=900&q=80'
    WHEN '018f0000-0000-7000-8002-000000000002'::uuid THEN 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=900&q=80'
    WHEN '018f0000-0000-7000-8002-000000000003'::uuid THEN 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=900&q=80'
    WHEN '018f0000-0000-7000-8002-000000000004'::uuid THEN 'https://images.unsplash.com/photo-1508061253366-f7da158b6d46?auto=format&fit=crop&w=900&q=80'
    WHEN '018f0000-0000-7000-8002-000000000005'::uuid THEN 'https://images.unsplash.com/photo-1596097635121-14b63b7a0c19?auto=format&fit=crop&w=900&q=80'
    WHEN '018f0000-0000-7000-8002-000000000006'::uuid THEN 'https://images.unsplash.com/photo-1515543904379-3d757afe72e4?auto=format&fit=crop&w=900&q=80'
    ELSE image_url
END,
updated_at = now()
WHERE id BETWEEN '018f0000-0000-7000-8002-000000000001'::uuid
             AND '018f0000-0000-7000-8002-000000000006'::uuid;

-- +goose Down
UPDATE foods
SET image_url = NULL,
    updated_at = now()
WHERE id BETWEEN '018f0000-0000-7000-8002-000000000001'::uuid
             AND '018f0000-0000-7000-8002-000000000006'::uuid;
