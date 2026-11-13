import express from 'express';
import pg from 'pg';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://localhost:5432/lottery_dashboard',
});

const app = express();
app.use(express.json());
app.use(express.static('public'));

const wrap = (fn) => (req, res) =>
  fn(req, res).catch((e) => { console.error(e); res.status(500).json({ error: e.message }); });

// KPI cards
app.get('/api/summary', wrap(async (_req, res) => {
  const { rows } = await pool.query(`
    SELECT COALESCE(SUM(amount) FILTER (WHERE status = 'Sold'), 0)::float AS total_sales,
           COUNT(*)::int                                                AS tickets,
           COUNT(*) FILTER (WHERE status = 'Canceled')::int             AS canceled
    FROM tickets`);
  res.json(rows[0]);
}));

// Lottery status table (sortable)
app.get('/api/lotteries', wrap(async (req, res) => {
  const col = req.query.sort === 'name' ? 'name' : 'sort_order';
  const dir = req.query.dir === 'desc' ? 'DESC' : 'ASC';
  const { rows } = await pool.query(
    `SELECT id, sort_order, name, status, result, close_time FROM lotteries ORDER BY ${col} ${dir}`);
  res.json(rows);
}));

// Charts: sales + ticket count per lottery
app.get('/api/sales-by-lottery', wrap(async (_req, res) => {
  const { rows } = await pool.query(`
    SELECT l.name, l.color,
           COALESCE(SUM(t.amount) FILTER (WHERE t.status = 'Sold'), 0)::float AS sales,
           COUNT(t.id) FILTER (WHERE t.status = 'Sold')::int                  AS tickets
    FROM lotteries l
    JOIN tickets t ON t.lottery_id = l.id
    GROUP BY l.id ORDER BY l.sort_order`);
  res.json(rows);
}));

// Actions: open/close a lottery, set its result
app.patch('/api/lotteries/:id', wrap(async (req, res) => {
  const { status, result } = req.body;
  const { rows } = await pool.query(
    `UPDATE lotteries SET status = COALESCE($1, status), result = COALESCE($2, result)
     WHERE id = $3 RETURNING *`, [status ?? null, result ?? null, req.params.id]);
  if (!rows.length) return res.status(404).json({ error: 'Not found' });
  res.json(rows[0]);
}));

// Record a ticket sale
app.post('/api/tickets', wrap(async (req, res) => {
  const { lottery_id, amount } = req.body;
  const { rows } = await pool.query(
    `INSERT INTO tickets (lottery_id, sold_by, amount) VALUES ($1, 1, $2) RETURNING *`,
    [lottery_id, amount]);
  res.status(201).json(rows[0]);
}));

// Cancel a ticket
app.post('/api/tickets/:id/cancel', wrap(async (req, res) => {
  const { rows } = await pool.query(
    `UPDATE tickets SET status = 'Canceled', canceled_at = now()
     WHERE id = $1 AND status = 'Sold' RETURNING *`, [req.params.id]);
  if (!rows.length) return res.status(404).json({ error: 'Not found or already canceled' });
  res.json(rows[0]);
}));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Dashboard on http://localhost:${port}`));
