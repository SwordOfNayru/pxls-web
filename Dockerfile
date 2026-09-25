# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Étape 1 : dépendances complètes (gulp, browserify… sont des devDependencies).
# ---------------------------------------------------------------------------
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci

# ---------------------------------------------------------------------------
# Étape 2 : `npm run build` (gulp) produit dist/ : JS traduit et minifié,
# CSS, thèmes, polices. Une variante par langue présente dans po/.
# ---------------------------------------------------------------------------
FROM deps AS build
WORKDIR /app
COPY .eslintrc gulpfile.js ./
COPY scripts ./scripts
COPY public ./public
COPY po ./po
RUN npm run build

# ---------------------------------------------------------------------------
# Étape 3 : image d'exécution, dépendances de production uniquement.
# ---------------------------------------------------------------------------
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

COPY index.js utils.js ./
COPY views ./views
COPY po ./po
COPY --from=build /app/dist ./dist
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# index.js fait `require('./config.json5')` : le fichier est écrit au
# démarrage depuis l'environnement, /app doit donc appartenir à `node`.
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && chown -R node:node /app

USER node
EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "index.js"]
