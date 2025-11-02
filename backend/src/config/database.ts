import pg from "pg";
import { loadEnv } from "./env";

const env = loadEnv();

const ssl = env.PGSSLMODE === "require" ? { rejectUnauthorized: false } : false;

const pool = env.DATABASE_URL
  ? new pg.Pool({ connectionString: env.DATABASE_URL, ssl })
  : new pg.Pool({
      host: env.PGHOST,
      port: env.PGPORT,
      user: env.PGUSER,
      password: env.PGPASSWORD,
      database: env.PGDATABASE,
      ssl
    });

export async function query<T = any>(text: string, params?: any[]): Promise<{ rows: T[] }> {
  const res = await pool.query<T>(text, params);
  return { rows: res.rows };
}

export { pool };
