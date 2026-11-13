-- Sample data shaped like the screenshot
INSERT INTO users (username, full_name, role) VALUES ('j.diaz', 'J. Diaz', 'Admin');

INSERT INTO lotteries (sort_order, name, status, result, color, close_time) VALUES
 (1,  'Texas Matin',      'Open',   NULL,       '#c5d08d', '10:00'),
 (2,  'Georgia Midi',     'Open',   NULL,       '#5ce63c', '12:20'),
 (3,  'Florida Midi',     'Open',   NULL,       '#44573a', '13:30'),
 (4,  'New York Midi',    'Open',   NULL,       '#0f7a9c', '14:30'),
 (5,  'Texas Ret',        'Closed', NULL,       '#c5d08d', '18:00'),
 (6,  'Georgia Soir',     'Closed', NULL,       '#5ce63c', '18:59'),
 (7,  'Florida Soir',     'Closed', NULL,       '#44573a', '21:45'),
 (8,  'New York Soir',    'Closed', NULL,       '#0f7a9c', '22:30'),
 (9,  'Anguila 8AM',      'Closed', '59-15-13', '#9aa7b8', '08:00'),
 (10, 'Anguila 9AM',      'Closed', '39-84-81', '#9aa7b8', '09:00'),
 (11, 'Tennessee Matin',  'Closed', NULL,       '#9aa7b8', '09:30'),
 (12, 'Anguila 10AM',     'Open',   NULL,       '#1e78e6', '10:00'),
 (13, 'La Primera Dia',   'Open',   NULL,       '#e02424', '12:00'),
 (14, 'LoteDom',          'Open',   NULL,       '#9ec5e8', '12:55'),
 (15, 'La Suerte MD',     'Open',   NULL,       '#f5c6a0', '12:30'),
 (16, 'Real',             'Open',   NULL,       '#e8a317', '12:55'),
 (17, 'Gana Mas',         'Open',   NULL,       '#3ee21c', '14:30'),
 (18, 'Loteria Nacional', 'Open',   NULL,       '#cfd6dd', '20:50');

-- Ticket counts / sales per lottery for today (only the ones shown on the chart)
WITH plan(name, n, total) AS (VALUES
  ('Texas Matin',      165, 33800),
  ('Georgia Midi',     245, 54500),
  ('Florida Midi',      70, 24600),
  ('New York Midi',     62, 27600),
  ('Anguila 10AM',      12,  2100),
  ('La Primera Dia',     8,  1500),
  ('LoteDom',            3,   600),
  ('La Suerte MD',       2,   300),
  ('Real',               6,  3600),
  ('Gana Mas',           5,  3381),
  ('Loteria Nacional',   2,   600)
)
INSERT INTO tickets (lottery_id, sold_by, amount, sold_at)
SELECT l.id, 1, round(p.total::numeric / p.n, 2),
       date_trunc('day', now()) + interval '7 hours' + (g * interval '1 minute')
FROM plan p
JOIN lotteries l ON l.name = p.name
CROSS JOIN generate_series(1, p.n) g;

-- Cancel 9 tickets
UPDATE tickets SET status = 'Canceled', canceled_at = sold_at + interval '5 minutes'
WHERE id IN (SELECT id FROM tickets ORDER BY random() LIMIT 9);
