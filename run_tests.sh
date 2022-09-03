#!/bin/sh

rm -f /tmp/res

find tests/ -name "*.lua" | while read file
do
  nvim --clean -u min.vim -c "redir > /tmp/res" -c "luafile $file" -c "quit"
done
cat /tmp/res
if ! grep -q "^not ok" /tmp/res
then
  exit 0
else
  exit 1
fi
