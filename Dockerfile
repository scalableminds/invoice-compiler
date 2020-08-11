FROM node:14

COPY . /app
WORKDIR /app

RUN yarn install --frozen-lockfile

CMD node server
