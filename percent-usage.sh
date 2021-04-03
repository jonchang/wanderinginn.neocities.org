#!/bin/sh

ORIGINAL=$(cat _site/texts/* | wc -c)
DIFF=$(cat _site/diffs/* | grep 'li class' | perl -pe 's{<li class="(?:unchanged|del|ins)">|</?(?:li|ins|del|span|strong)>}{}g' | wc -c)

echo "scale=4;$DIFF/$ORIGINAL" | bc
