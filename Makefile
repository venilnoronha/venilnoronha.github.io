# make builder
# make serve
# make publish

.PHONY: builder
builder:
	docker build -t venilnoronha/site-builder:latest . --progress plain

.PHONY: serve
serve:
	docker run -it --rm -v $$PWD:/site:rw -p 4000:4000 venilnoronha/site-builder:latest -- \
		"bundle exec jekyll serve --host=0.0.0.0 --incremental"

.PHONY: build-prod
build-prod:
	rm -rf /tmp/jasper2-pages
	docker run -it --rm -v /tmp/jasper2-pages:/jasper2-pages:rw -v $$PWD:/site:rw venilnoronha/site-builder:latest -- \
		"JEKYLL_ENV=production bundle exec jekyll build"

.PHONY: confirm-publish
confirm-publish:
	@echo -n "Are you sure? " && read ans && [ $$ans == y ]

.PHONY: publish
publish: confirm-publish build-prod
	git checkout master || git checkout -b master origin/master
	git rebase origin/master
	cp -R /tmp/jasper2-pages/* .
	git status
	rm -rf /tmp/jasper2-pages
