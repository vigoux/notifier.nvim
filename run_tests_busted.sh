#!/bin/sh
BUSTED_VERSION="2.1.2-3"
luarocks init
luarocks install busted "$BUSTED_VERSION"
luarocks config --scope project lua_version 5.1
nvim --clean -u min.lua \
  -c "lua package.path='lua_modules/share/lua/5.1/?.lua;lua_modules/share/lua/5.1/?/init.lua;'..package.path;package.cpath='lua_modules/lib/lua/5.1/?.so;'..package.cpath;local k,l,_=pcall(require,'luarocks.loader') _=k and l.add_context('busted','$BUSTED_VERSION')" \
  -l "lua_modules/lib/luarocks/rocks-5.1/busted/$BUSTED_VERSION/bin/busted" "$@"
