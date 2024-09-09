.PHONY: all install sync update clean lint test serve
#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PYTHON_INTERPRETER = python3.11

#################################################################################
# COMMANDS                                                                      #
#################################################################################
all:
	echo $(AWS_PROFILE)

## Init poetry dependencies
init:
	pip install --upgrade pip
	pip install pipx
	pipx install poetry==1.8.2
	poetry env use python3.11
	poetry shell

## Install train dependencies in pyproject.toml (poetry.lock)
install:
	poetry lock
	poetry install --sync
	pipx inject poetry poetry-plugin-export
	poetry export -f requirements.txt --output requirements.txt
	pre-commit install
	pre-commit run --all-files

## Sync dependencies in .venv with poetry.lock
sync:
	poetry lock
	poetry lock --no-update
	poetry install --sync
	poetry export -f requirements.txt --output requirements.txt

## Delete all compiled Python files
clean:
	find . -type f -name "*.DS_Store" -ls -delete
	find . -type f -name "*.py[co]" -delete
	find . -type f -name "*.log" -delete
	find . -type f -name "*.logs" -delete
	find . -type f -name "*.coverage*" -delete
	find . -type f -name "*.temp" -delete
	find . -type d -name "*.coverage" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name "*.coverage" -exec rm -rf {} +
	find . -type d -name "*.eggs" -exec rm -rf {} +
	find . -type d -name "*.pytest_cache" -exec rm -rf {} +
	find . -type d -name "*.*cache" -exec rm -rf {} +
	find . -type d -name "*.venv" -exec rm -rf {} +
	find . | grep -E ".ipynb_checkpoints" | xargs rm -rf
	find . -type d -empty -delete

## Lint
lint:
	ruff format .
	ruff check --fix
	## nbqa ruff notebooks
	## nbqa ruff notebooks --fix
	pre-commit run --all-files

## Clean logs
clean-logs:
	rm -rf *logs/**

## Run tests
test:
	pytest -svv

# ## Train the model
# train:
# 	python src/train.py

## Serve the model
serve:
	python src/serve.py

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
