const fs = require('fs');
const path = require('path');
const { pool } = require('../db');

async function run() {
  const dir = path.resolve(__dirname, '../../migrations');
  const files = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(dir, file), 'utf8');
    process.stdout.write(`Applying migration ${file}...\n`);
    await pool.query(sql);
  }
  process.stdout.write('Migrations completed.\n');
  await pool.end();
}

run().catch(async (e) => {
  process.stderr.write(`Migration failed: ${e.message}\n`);
  await pool.end();
  process.exit(1);
});
