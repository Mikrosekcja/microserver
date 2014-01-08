PATH			:=./node_modules/.bin/:$(HOME)/.npm-packages/bin/:$(PATH)
BROWSERIFY:= $(shell cat .browserify | sed 's/.*/-r & /g')

# $(for package in $(cat .browserify); do echo -n " -r $package"; done)
all: install build test start

clean:
	rm -rf lib/*
	rm -rf assets/scripts/app/*

init:
	if [ -e npm-shrinkwrap.json ]; then rm npm-shrinkwrap.json; fi
	mkdir -p assets/scripts/app/
	mkdir -p scripts
	touch .browserify

	npm install

browserify:
	mkdir -p assets/scripts/app/
	browserify $(BROWSERIFY) > assets/scripts/app/browserified.js

build: clean init # browserify
	./node_modules/.bin/coffee -cm -o lib src
	./node_modules/.bin/coffee -cm -o assets/scripts/app/ scripts/

watch: end-watch
	./node_modules/.bin/coffee -cmw -o lib src          						 & echo $$! > .watch_pid
	./node_modules/.bin/coffee -cmw -o assets/scripts/app/ scripts/  & echo $$! > .watch_frontend_pid
	./node_modules/.bin/stylus -w   -o assets/styles/app   styles/   & 

end-watch:
	if [ -e .watch_pid ]; then kill `cat .watch_pid`; rm .watch_pid;  else  echo no .watch_pid file; fi
	if [ -e .watch_frontend_pid ]; then kill `cat .watch_frontend_pid`; rm .watch_frontend_pid; else echo no .watch_pid file; fi

dev: watch
	NODE_ENV=development DEBUG=microserver,microserver:* nodemon lib/app.js

start:
	npm start

forever: build
	forever lib/app.js

test:
	npm test

docs:
	echo "Error: no docs generator installed"
	# ./node_modules/.bin/groc "src/*.coffee?(.md)" "src/**/*.coffee?(.md)" readme.md

clean-docs:
	rm -rf docs/*
