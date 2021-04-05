ifndef MK_HELP
MK_HELP=1

.PHONY: help
.DEFAULT_GOAL := help

# This target reads the Makefile and extracts all the targets that have a comment
# to display a help message
help: ## Display this help message
	@echo $(MAKEFILE_LIST) | tr ' ' '\n' | sort | uniq | xargs grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-50s\033[0m %s\n", $$1, $$2}'


endif
