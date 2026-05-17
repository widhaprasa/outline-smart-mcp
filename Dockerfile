# Use a slim Node.js image for a smaller footprint
FROM node:20.20.2-bookworm-slim AS builder

# Set the working directory
WORKDIR /app

# Copy package files first to leverage Docker caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the source code
COPY . .

# Build the project (compiles TypeScript to JavaScript)
RUN npm run build

# --- Runtime Stage ---
FROM node:20.20.2-bookworm-slim AS runner

WORKDIR /app

# Copy only the production dependencies and built files
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

# Set environment variables (can be overridden at runtime)
# Outline requires an API Key and Base URL
ENV OUTLINE_URL=""
ENV OUTLINE_API_TOKEN=""

# Install mcp-proxy
RUN npm install -g mcp-proxy

# Expose the network port
EXPOSE 8080

# Use mcp-proxy to expose the stdio script over an isolated HTTP endpoint
CMD ["mcp-proxy", "--port", "8080", "node", "dist/index.js"]
