
PHONY:init
init:
	cd validation; \
	npm install;


PHONY:test
test:
	cd validation; \
	npm run test;
