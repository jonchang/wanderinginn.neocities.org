set -u

: "$NEOCITIES_API_KEY"

neocities push _site

TERM=dumb neocities list -a | sort > /tmp/theirs.txt
find _site | sed "s|^_site/||" | sort > /tmp/ours.txt
comm -2 -3 /tmp/theirs.txt /tmp/ours.txt > /tmp/remove.txt
if [ -s /tmp/remove.txt ]; then
    wc -l /tmp/remove.txt
    echo "Deleting files"
    cat /tmp/remove.txt | xargs neocities delete
fi

rm /tmp/theirs.txt /tmp/ours.txt /tmp/remove.txt
