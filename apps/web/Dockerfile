FROM node:14-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --only=production --legacy-peer-deps && npm cache clean --force
COPY . .
ENV PORT=4000 \
    API_HOST=
EXPOSE 4000
USER node
CMD [ "node", "./src/bin/www" ]
