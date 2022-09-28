#!/bin/sh

RES_FILE="/tmp/res"

rm -f "$RES_FILE"

find tests/ -name "*.lua" | while read file
do
  nvim --headless --clean -u min.lua -c "redir >> $RES_FILE" -c "luafile $file" -c "quit" 2> /dev/null
done
cat "$RES_FILE"
if ! grep -q "^not ok" "$RES_FILE"
then
  exit 0
else
  exit 1
fi
