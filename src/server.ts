import { buildApp } from "./app.js";
import { env } from "./config/env.js";

async function start() {
  const app = await buildApp();

  try {
    const address = await app.listen({
      host: env.HOST,
      port: env.PORT,
    });

    app.log.info({ address }, "BookQHub Catalog Service started");

    const shutdown = async (signal: string) => {
      app.log.info({ signal }, "Shutdown signal received");

      try {
        await app.close();

        app.log.info("Application closed successfully");
      } catch (error) {
        app.log.error({ err: error }, "Error during application shutdown");

        process.exitCode = 1;
      }
    };

    process.once("SIGINT", () => void shutdown("SIGINT"));
    process.once("SIGTERM", () => void shutdown("SIGTERM"));
  } catch (error) {
    app.log.error({ err: error }, "Failed to start Catalog Service");

    await app.close();
    process.exitCode = 1;
  }
}

void start();
