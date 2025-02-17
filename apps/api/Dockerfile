FROM node:14-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --only=production --legacy-peer-deps && \
    npm cache clean --force && \
    rm -rf /tmp/* /var/cache/apk/*
COPY . .
ENV PORT=3000 \
    DBUSER='' \
    DB='' \
    DBPASS='' \
    DBHOST='' \
    DBPORT=5432
USER node
EXPOSE 3000
CMD ["npm", "start"]
