FROM monokrome/node

MAINTAINER Tadeusz Łazurski <tadeusz@lazurski.pl>

RUN mkdir /app

ADD . /app

CMD ["node", "/app/lib/app.js"]