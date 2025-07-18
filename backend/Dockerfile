# Build stage - Dependencies
FROM node:18-alpine as dependencies

WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./

# Install all dependencies (production + development)
RUN npm ci --include=dev && \
    npm cache clean --force

# Build stage - Application preparation
FROM node:18-alpine as build

WORKDIR /app

# Copy dependencies from previous stage
COPY --from=dependencies /app/node_modules ./node_modules
COPY package*.json ./

# Copy source code
COPY . .

# Run any build steps if needed (linting, compilation, etc.)
RUN npm run lint --if-present || echo "No lint script found" && \
    npm run build --if-present || echo "No build script found"

# Production stage - Runtime
FROM node:18-alpine as production

# Install curl for health checks and dumb-init for proper signal handling
RUN apk add --no-cache curl dumb-init

# Create app user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production --silent && \
    npm cache clean --force

# Copy application code from build stage
COPY --from=build /app .

# Remove unnecessary files to reduce image size
RUN rm -rf __tests__ *.test.js *.spec.js coverage/ .nyc_output/ \
    docs/ examples/ test/ tests/ .eslintrc* .prettierrc* \
    *.md README* CHANGELOG* LICENSE* .git* .docker*

# Change ownership to nodejs user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

EXPOSE 5000

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:5000/health || curl -f http://localhost:5000/ || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["npm", "start"]
