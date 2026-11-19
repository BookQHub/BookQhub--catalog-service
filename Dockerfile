# Service image building

FROM node:22-alpine

WORKDIR /app

# Enable pnpm through Corepack
RUN corepack enable

# Copy dependency manifests first for better layer caching
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install --frozen-lockfile

# Copy TypeScript configuration and application source
COPY tsconfig.json ./
COPY src ./src

EXPOSE 3000

CMD ["npm", "run", "dev"]
