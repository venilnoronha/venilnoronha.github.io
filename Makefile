.PHONY: serve
serve:
	bundle exec jekyll serve

.PHONY: build-prod
build-prod:
	rm -rf ../jasper2-pages
	JEKYLL_ENV=production bundle exec jekyll build

.PHONY: confirm-publish
confirm-publish:
	@echo -n "Are you sure? " && read ans && [ $$ans == y ]

.PHONY: publish
publish: confirm-publish build-prod
	git checkout master || git checkout -b master origin/master
	git rebase origin/master
	cp -R ../jasper2-pages/* .
	git status
	rm -rf ../jasper2-pages
