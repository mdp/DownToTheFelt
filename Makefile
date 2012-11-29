PROJECT = "Down To The Felt"

all: clean build compress

test: ;@echo "Testing ${PROJECT}....."; \
    export NODE_PATH=.; \
      ./node_modules/mocha/bin/mocha;

compress: ;@echo "Smashing ${PROJECT}....."; \
    uglifyjs lib/player.js > lib/player.min.js

build: ;@echo "Building ${PROJECT}....."; \
    coffee -co lib src

clean : ;@echo "Deleting build directory"; \
        rm -rf lib


.PHONY: build clean compress
