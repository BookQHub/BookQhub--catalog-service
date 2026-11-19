import Fastify from "fastify";

import { env } from "./config/env.js";
import { createPostgresPool } from "./database/postgres.js";
import healthRoutes from "./modules/books/routes/health.routes.js";

interface AppOptions {
  pool?: import("pg").Pool;
}

export async function buildApp(options: AppOptions = {}) {
  const app = Fastify({
    logger: {
      level: env.LOG_LEVEL,
    },
  });

  const pool = options.pool ?? createPostgresPool();

  app.decorate("db", pool);

  pool.on("error", (error) => {
    app.log.error(
      { err: error },
      "Unexpected error on idle PostgreSQL connection",
    );
  });

  // Close the database pool when Fastify closes.
  app.addHook("onClose", async () => {
    await pool.end();
  });

  await app.register(healthRoutes, {
    prefix: "/health",
  });

  return app;
}
