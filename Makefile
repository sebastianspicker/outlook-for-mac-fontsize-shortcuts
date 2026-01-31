LUAROCKS_TREE ?= ./.luarocks

LUACHECK := $(LUAROCKS_TREE)/bin/luacheck
BUSTED := $(LUAROCKS_TREE)/bin/busted

.PHONY: tools lint fmt fmt-check test clean

tools:
	@command -v luarocks >/dev/null || (echo "Missing 'luarocks' (try: brew install luarocks)" && exit 1)
	@mkdir -p $(LUAROCKS_TREE)
	@luarocks --tree $(LUAROCKS_TREE) install luacheck
	@luarocks --tree $(LUAROCKS_TREE) install busted

lint: $(LUACHECK)
	@$(LUACHECK) .

fmt:
	@command -v stylua >/dev/null || (echo "Missing 'stylua' (try: brew install stylua)" && exit 1)
	@stylua .

fmt-check:
	@command -v stylua >/dev/null || (echo "Missing 'stylua' (try: brew install stylua)" && exit 1)
	@stylua --check .

test: $(BUSTED)
	@$(BUSTED)

clean:
	@echo "Removing $(LUAROCKS_TREE)"
	@luarocks --tree $(LUAROCKS_TREE) purge --old-versions || true

