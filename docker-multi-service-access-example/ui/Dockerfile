# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Copy built app and package files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# Install dependencies including Vite for preview
RUN npm ci

# Expose port
EXPOSE 3001

# Start the server using Vite preview
CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0", "--port", "3001"] 