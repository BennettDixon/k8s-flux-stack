# This docker file builds a Hello world node app
FROM node:14-alpine
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 4321
CMD ["node", "app.js", "--port", "4321"]
