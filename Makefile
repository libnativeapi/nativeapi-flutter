.PHONY: status sync bump

# Working-tree status of every submodule
status:
	@git submodule foreach --quiet 'echo "== $$name ($$(git branch --show-current))"; git status --short'

# Fast-forward every submodule to origin/main
sync:
	git submodule update --remote --merge

# Stage updated submodule pointers
bump:
	git add core bindings/flutter bindings/rust bindings/csharp
	@git status --short
