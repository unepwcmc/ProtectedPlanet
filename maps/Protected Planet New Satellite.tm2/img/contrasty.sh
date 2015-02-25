# !/bin/bash

# generate a list with any svg with any rect/path that has #666666 or #666677 as a fill
#   we dont want to change any fills but these
svgs=$(grep -Rn 'fill:#666666\|fill:#666677' ./*/*svg | sed 's+:.*++g')

# for every svg in the list we just generated, make that fill #333333
for svg in $svgs; do
    # echo $svg
    sed -i '' 's/fill:#666666/fill:#333333/g;s/fill:#666677/fill:#333333/g;' $svg
done


# convert raster assets
for png in $(ls ./shield/*png); do
    convert -solarize 50% $png $png
done

# TODO: make this less brittle. maybe specify allow you specify a (1)hex value you want
# 	to replace, and (2) that value's replacement