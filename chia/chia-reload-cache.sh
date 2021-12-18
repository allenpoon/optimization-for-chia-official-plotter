pid=$1
log_file=$2
numa_node=$3
# echo "$pid" "$log_file"

is_exist=$(ps aux | grep "chia " | grep -v "grep" | awk '{print $2}' | grep $pid)
# echo $is_exist
while [ "$is_exist" != "" ] && [ "$phase" != "6" ]; do
  result=$(sh /mnt/chia-script/chia-check-phase.sh $log_file)
  phase=$(echo $result | awk '{print $1}')
  is_exist=$(ps aux | grep "chia " | grep -v "grep" | awk '{print $2}' | grep $pid)
  if [ "$is_exist" != "" ]; then
    if [ "$phase" != "$old_phase" ]; then
      if [ "$phase" = "1" ]; then
        renice -n -5 -p $pid
      elif [ "$phase" = "2" ]; then
        renice -n -3 -p $pid
      elif [ "$phase" = "3" ]; then
        renice -n -1 -p $pid
      fi
      old_phase=$phase
    fi

    sh /mnt/chia-script/chia-cache.sh $pid $log_file $numa_node
  fi
done
