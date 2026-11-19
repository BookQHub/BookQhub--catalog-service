import { Pool } from "pg";
import { env } from "../config/env.js";

export const createPostgresPool = (): Pool => {
  return new Pool({
    connectionString: env.DATABASE_URL,
    max: env.DATABASE_POOL_MAX,
    connectionTimeoutMillis: env.DATABASE_CONNECTION_TIMEOUT_MS,
    idleTimeoutMillis: env.DATABASE_IDLE_TIMEOUT_MS,
    ssl: env.DATABASE_SSL ? { rejectUnauthorized: true } : false,
    application_name: "BookQHub-catalog-service",
  });
};
