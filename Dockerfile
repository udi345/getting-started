# --------------------
# Stage 1: Python base
# --------------------
FROM python:3.10-alpine AS base
WORKDIR /app

# Install dependencies
COPY requirements.txt .
# Use --no-cache-dir to reduce image size
RUN pip install --no-cache-dir -r requirements.txt

# --------------------
# Stage 2: Node base for app
# --------------------
FROM node:18-alpine AS app-base
WORKDIR /app

# Copy app package files
COPY app/package.json app/yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy app source code and spec files
COPY app/src ./src
COPY app/spec ./spec

# Run tests
RUN yarn test

# --------------------
# Stage 3: Zip the app
# --------------------
FROM node:18-alpine AS app-zip-creator
WORKDIR /app

COPY --from=app-base /app/package.json /app/yarn.lock ./
COPY app/spec ./spec
COPY --from=app-base /app/src ./src

# Install zip utility and create zip
RUN apk add --no-cache zip && zip -r /app.zip /app

# --------------------
# Stage 4: Nginx for deployment
# --------------------
FROM nginx:alpine AS stage-6

# Copy app zip to nginx
COPY --from=app-zip-creator /app.zip /usr/share/nginx/html/assets/app.zip

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
