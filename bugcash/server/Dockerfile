# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Production stage
FROM node:18-alpine

# Install system dependencies
RUN apk add --no-cache \
    libc6-compat \
    ca-certificates \
    tzdata

# Create app directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S bugcash -u 1001

# Copy built node modules and app code
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=bugcash:nodejs . .

# Set environment
ENV NODE_ENV=production
ENV TZ=Asia/Seoul

# Switch to non-root user
USER bugcash

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node src/health-check.js

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]