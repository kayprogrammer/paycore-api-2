.PHONY: setup server console db-migrate db-setup test lint routes

setup:
	bundle install
	bundle exec rails db:prepare

server:
	bundle exec rails server -p 3000

console:
	bundle exec rails console

db-migrate:
	bundle exec rails db:migrate

db-setup:
	bundle exec rails db:setup

test:
	bundle exec rspec

lint:
	bundle exec rubocop -a

routes:
	bundle exec rails routes
