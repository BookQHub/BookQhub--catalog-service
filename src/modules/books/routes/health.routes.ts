import type { FastifyPluginAsync } from "fastify";

const healthRoutes: FastifyPluginAsync = async (app) => {
  // Liveness: is the application process running?
  app.get("/live", async () => {
    return {
      status: "ok",
    };
  });

  // Readiness: can the application serve requests?
  app.get("/ready", async (_request, reply) => {
    try {
      await app.db.query("SELECT 1");

      return {
        status: "ok",
        dependencies: {
          database: "ok",
        },
      };
    } catch (error) {
      app.log.error({ err: error }, "Database readiness check failed");

      return reply.code(503).send({
        status: "error",
        dependencies: {
          database: "unavailable",
        },
      });
    }
  });
};

export default healthRoutes;
