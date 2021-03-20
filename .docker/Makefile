export RUBY_IMAGE ?= ruby:3.0-buster

.PHONY: up
up:
	docker-compose up

.PHONY: down
down:
	docker-compose down

.PHONY: test
test: rspec

.PHONY: ssh
ssh:
	docker-compose run cli bash

.PHONY: rspec
rspec:
	docker-compose run cli bin/rspec

.PHONY: setup
setup:
	docker-compose build --build-arg RUBY_IMAGE=${RUBY_IMAGE}
	docker-compose run cli bin/setup
