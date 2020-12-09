for f in *-*[0-9] ; do
    echo ---- processing $f ----
    avg_117.pl $f
done
