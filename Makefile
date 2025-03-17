help:
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

serve-ruby: ## Run the website via standard system or RVM installed ruby+bundler
	bundle exec jekyll serve --livereload

serve-docker: ## Build and run in a ruby:3.2 docker container. Should be podman compatible.
	./serve.sh
