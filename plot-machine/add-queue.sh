target=$1
name=$2
command=$3

if [ "$target" != "chia-evict" ] && [ "$target" != "chia-cache-long" ] && [ "$target" != "chia-cache-p1-short" ] && [ "$target" != "chia-cache-p3-short" ] && [ "$target" != "chia-cache-final" ]; then
  echo "target error, target=$target"
fi

# find same command
is_exist=$(ls /mnt/cache/$target | grep $name)
# add to queue
if [ "$is_exist" = "" ]; then
  echo $command > "/mnt/cache/$target/$name"
fi
