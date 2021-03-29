SHELL := /bin/bash

MODULE         := $(notdir $(PWD))
USERID          = $(shell id -u)
USERGROUP       = $(shell id -g)
DATE_TIME       = $(shell date +%s)
GCP_CREDS_FILE  = $(notdir ${GOOGLE_CREDENTIALS})

.PHONY: readme test

clear-env-error:
	$(eval ENV_ERROR =)

check-error:
	@if [ ! "${ENV_ERROR}" = "" ]; then echo -e "${ENV_ERROR}" && exit 1; fi

check-env:
	$(eval GOOGLE_AUTH = GOOGLE_APPLICATION_CREDENTIALS=/root/$(GCP_CREDS_FILE))
ifneq ('$(GOOGLE_IMPERSONATE_SERVICE_ACCOUNT)', '')
	$(eval GOOGLE_AUTH = GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT})
endif
ifeq ($(GOOGLE_CREDENTIALS), )
ifeq ('$(GOOGLE_IMPERSONATE_SERVICE_ACCOUNT)', '')
	$(eval ENV_ERROR = $(ENV_ERROR)Either GOOGLE_CREDENTIALS or GOOGLE_IMPERSONATE_SERVICE_ACCOUNT should be set but was not found in environment.\n)
endif
endif
ifeq ($(GOOGLE_CLOUD_PROJECT), )
	$(eval ENV_ERROR = $(ENV_ERROR)GOOGLE_CLOUD_PROJECT is not set in environment.\n)
endif

check-gcp-env: clear-env-error check-env check-error

test: check-gcp-env $(GOOGLE_CREDENTIALS)
	docker run --rm -it \
	-v $(HOME)/.config/gcloud:/root/.config/gcloud \
	-v $(PWD):/go/src/app/ \
	-e GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT} \
	-e $(GOOGLE_AUTH) \
	-e TF_VAR_owner=$(USER) \
	binxio/terratest-runner-gcp:latest \
	/bin/sh -c 'go test -v ./test -timeout 60m | tee -a terratest.log && /go/bin/terratest_log_parser --testlog terratest.log --outputdir out --log-level warning && cat out/summary.log'

readme:
	docker run --rm -e MODULE=$(MODULE) --user $(USERID):$(USERGROUP) -it -v $(PWD):/go/src/app/$(MODULE) binxio/terraform-module-readme-generator:latest
