while read p;
do
    echo "$p"
    merge_galaxy.sh $p
done <releases
