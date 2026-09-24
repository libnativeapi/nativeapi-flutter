.PHONY: status sync bump

# Working-tree status of this repository and every submodule
status:
	@echo "== workspace ($$(git branch --show-current))"; git status --short --ignore-submodules=all
	@git submodule foreach --quiet 'echo "== $$name ($$(git branch --show-current))"; git status --short'

# Fast-forward core to origin/main
sync:
	git submodule update --remote --merge core

# Stage an updated core pointer
bump:
	git add core
	@git status --short
