.PHONY: serve
serve:
	bundle exec jekyll serve

.PHONY: serve-prod
serve-prod:
	JEKYLL_ENV=production bundle exec jekyll serve
