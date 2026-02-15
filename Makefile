VERSION_FILE  := VERSION
IMAGE         := ghcr.io/thehappylab/openclaw

CURRENT       := $(shell cat $(VERSION_FILE) 2>/dev/null || echo "0.0.0-0")
TODAY         := $(shell date -u +'%Y.%-m.%-d')
CUR_DATE      := $(word 1,$(subst -, ,$(CURRENT)))
CUR_COUNTER   := $(word 2,$(subst -, ,$(CURRENT)))

ifeq ($(TODAY),$(CUR_DATE))
  NEXT_COUNTER := $(shell expr $(CUR_COUNTER) + 1)
else
  NEXT_COUNTER := 1
endif

NEXT          := $(TODAY)-$(NEXT_COUNTER)

.PHONY: version bump

## Show current version
version:
	@echo $(CURRENT)

## Bump version (date + counter), inject into all tracked files
bump:
	@echo "$(CURRENT) → $(NEXT)"
	@echo "$(NEXT)" > $(VERSION_FILE)
	@sed -i "s|image: '$(IMAGE):[^']*'|image: '$(IMAGE):$(NEXT)'|" docker-compose.coolify.yaml
	@sed -i 's|^\*\*Version:\*\* `[^`]*`|**Version:** `$(NEXT)`|' README.md
	@sed -i "s|BUILD_VERSION=.*|BUILD_VERSION=$(NEXT)|" .github/workflows/build.yml
	@echo "✓ Bumped to $(NEXT)"
	@echo "  - VERSION"
	@echo "  - docker-compose.coolify.yaml"
	@echo "  - .github/workflows/build.yml"
	@echo "  - README.md"
