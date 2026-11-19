import { config } from "dotenv";

config();
const required = (name: string): string => {
  const value = process.env[name]?.trim();

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
};

const parseInteger = (
  name: string,
  value: string | undefined,
  defaultValue: number,
  min: number,
  max: number,
): number => {
  const parsed = value === undefined ? defaultValue : Number(value);

  if (!Number.isInteger(parsed) || parsed < min || parsed > max) {
    throw new Error(`${name} must be an integer between ${min} and ${max}`);
  }

  return parsed;
};

const parseBoolean = (
  name: string,
  value: string | undefined,
  defaultValue: boolean,
): boolean => {
  if (value === undefined) return defaultValue;

  if (value === "true") return true;
  if (value === "false") return false;

  throw new Error(`${name} must be "true" or "false"`);
};

const databaseUrl = required("DATABASE_URL");

try {
  const parsedUrl = new URL(databaseUrl);

  if (
    parsedUrl.protocol !== "postgres:" &&
    parsedUrl.protocol !== "postgresql:"
  ) {
    throw new Error("Invalid protocol");
  }
} catch {
  throw new Error("DATABASE_URL must be a valid PostgreSQL connection URL");
}

const nodeEnv = process.env.NODE_ENV ?? "development";

if (!["development", "production", "test"].includes(nodeEnv)) {
  throw new Error("NODE_ENV must be development, production, or test");
}

const logLevel = process.env.LOG_LEVEL ?? "info";

if (
  !["fatal", "error", "warn", "info", "debug", "trace", "silent"].includes(
    logLevel,
  )
) {
  throw new Error("Invalid LOG_LEVEL");
}

export const env = Object.freeze({
  NODE_ENV: nodeEnv,

  HOST: process.env.HOST ?? "0.0.0.0",

  PORT: parseInteger("PORT", process.env.PORT, 3000, 1, 65535),

  LOG_LEVEL: logLevel,

  DATABASE_URL: databaseUrl,

  DATABASE_SSL: parseBoolean("DATABASE_SSL", process.env.DATABASE_SSL, false),

  DATABASE_POOL_MAX: parseInteger(
    "DATABASE_POOL_MAX",
    process.env.DATABASE_POOL_MAX,
    10,
    1,
    100,
  ),

  DATABASE_CONNECTION_TIMEOUT_MS: parseInteger(
    "DATABASE_CONNECTION_TIMEOUT_MS",
    process.env.DATABASE_CONNECTION_TIMEOUT_MS,
    5000,
    100,
    60000,
  ),

  DATABASE_IDLE_TIMEOUT_MS: parseInteger(
    "DATABASE_IDLE_TIMEOUT_MS",
    process.env.DATABASE_IDLE_TIMEOUT_MS,
    10000,
    1000,
    60000,
  ),
});

export type Environment = typeof env;
