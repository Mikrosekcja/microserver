# TODO: Move to official node image
# FROM node

FROM monokrome/node

MAINTAINER Tadeusz Łazurski <tadeusz@lazurski.pl>

RUN mkdir /app
RUN npm i -g pm2@latest

# TODO: Consifer using volumes
ADD . /app
WORKDIR /app

# TODO: Improve Controllers module to allow cluster mode and drop -x
CMD ["pm2", "start", "lib/app.js", "-x", "--no-daemon"]
