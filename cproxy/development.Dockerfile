FROM node:current-alpine
RUN apk add --update --no-cache curl

WORKDIR /usr/src/app/cproxy

CMD [ "yarn", "dev" ]
