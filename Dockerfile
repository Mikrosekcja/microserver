# TODO: Move to official node image
# FROM node
# TODO: or use https://github.com/phusion/passenger-docker

FROM monokrome/node

MAINTAINER Tadeusz Łazurski <tadeusz@lazurski.pl>

RUN mkdir /app
RUN npm i -g pm2@latest

# TODO: Consider using volumes
ADD . /app
WORKDIR /app

# TODO: Improve Controllers module to allow cluster mode and drop -x
CMD ["pm2", "start", "lib/app.js", "-x", "--no-daemon"]
