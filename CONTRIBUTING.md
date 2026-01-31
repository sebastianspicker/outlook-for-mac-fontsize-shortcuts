# Contributing

## Local dev

Tooling:

```bash
brew install lua luarocks stylua
make tools
```

Quality gates:

```bash
make fmt
make lint
make test
```

## Hammerspoon smoke test

Copy files into `~/.hammerspoon/` and reload Hammerspoon:

```bash
cp outlook-font.lua ~/.hammerspoon/outlook-font.lua
cp -R outlook_font  ~/.hammerspoon/outlook_font
cp init.lua         ~/.hammerspoon/init.lua
```

