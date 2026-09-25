#!/bin/sh
# Génère config.json5 depuis l'environnement : index.js le charge au démarrage
# et il n'a donc pas à être monté depuis l'hôte.
set -eu

: "${WEB_PORT:=3000}"
: "${WEB_PROXY_TO:=pxls-server:4567}"
: "${WEB_TITLE:=Pxls}"

# Passe par node pour l'échappement : un titre avec une apostrophe ou un
# accent produirait sinon un JSON5 invalide.
node -e '
  const fs = require("fs");
  fs.writeFileSync("/app/config.json5", JSON.stringify({
    port: Number(process.env.WEB_PORT),
    proxyTo: process.env.WEB_PROXY_TO,
    title: process.env.WEB_TITLE
  }, null, 2) + "\n");
'

exec "$@"
