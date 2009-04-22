for dirname in `du  ./* | sort -rn | cut -f2- | head -5`
do
 echo ""
 echo Big directory: $dirname
 echo Four largest files in that directory are:
 find $dirname -type f -printf "%k %p\n" | sort -rn | head -4
done
exit 0
