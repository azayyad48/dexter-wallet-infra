# Alpine keeps the image small (~130MB vs ~1GB for the full node image),
# which means faster pulls, faster scaling, less attack surface.
FROM node:20-alpine

WORKDIR /app

# No npm dependencies, so no package install step. If deps get added later:
# COPY package*.json ./
# RUN npm ci --omit=dev
COPY package.json server.js ./

ENV PORT=8080
EXPOSE 8080

# The node image ships a non-root 'node' user - use it. Containers
# running as root are the single most common Dockerfile finding.
USER node

# Lets docker/compose (and anything watching container state) know the
# app is actually serving, not just that the process exists.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1

CMD ["node", "server.js"]
