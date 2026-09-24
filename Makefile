.PHONY: status sync bump

# Working-tree status of this repository and every submodule
status:
	@echo "== workspace ($$(git branch --show-current))"; git status --short --ignore-submodules=all
	@git submodule foreach --quiet 'echo "== $$name ($$(git branch --show-current))"; git status --short'

# Fast-forward every submodule to origin/main
sync:
	git submodule update --remote --merge core bindings/rust bindings/csharp

# Stage updated submodule pointers
bump:
	git add core bindings/rust bindings/csharp
	@git status --short
