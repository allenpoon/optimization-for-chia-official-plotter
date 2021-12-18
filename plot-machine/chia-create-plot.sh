is_test_copy_final=$(/chia-blockchain/miner_config.sh is_test_copy_final 2>/dev/null)
#numa_node=0-23
#numa_node=$(/mnt/chia-script/get_next_numa.sh)
date=$(date +"%Y%m%dT%H%M%S")
#id=$(cat /etc/hostname)
#if [ "$is_test_copy_final" = "1" ]; then
  #taskset -c $numa_node sh -c "exec /chia-blockchain/venv/bin/chia plots create -k 32 -n 1 -b 4608 -r 4 -u 128 -f b3fdfc0e00d35a44ab05b2a4edfb554e07eea217b9b3d6e3e1c559a7a786f50a25d573b8d20e5d9f228e578b5ff0ecc3 -c xch1mshh7s9hhguxqvzwle7nazerppuw393laldnqr6yfg74hk2fyr0st90sts  -t /mnt/chia-farmer/tmp/ -d /mnt/chia-farmer/tmp/ > /mnt/cache/log/$date-\$\$.log" &
  nice --5 ionice -c 3 sh -c "exec /chia-blockchain/venv/bin/chia plots create -k 32 -n 1 -b 4608 -r 4 -u 128 -f b3fdfc0e00d35a44ab05b2a4edfb554e07eea217b9b3d6e3e1c559a7a786f50a25d573b8d20e5d9f228e578b5ff0ecc3 -c xch1mshh7s9hhguxqvzwle7nazerppuw393laldnqr6yfg74hk2fyr0st90sts  -t /mnt/chia-farmer/tmp/ -d /mnt/chia-farmer/tmp/ > /mnt/cache/log/$date-\$\$.log" &
#else
#  sh -c "exec /chia-blockchain/venv/bin/chia plots create -k 32 -n 1 -b 4608 -r 4 -u 128 -f b3fdfc0e00d35a44ab05b2a4edfb554e07eea217b9b3d6e3e1c559a7a786f50a25d573b8d20e5d9f228e578b5ff0ecc3 -c xch1mshh7s9hhguxqvzwle7nazerppuw393laldnqr6yfg74hk2fyr0st90sts  -t /mnt/chia-farmer/tmp/ -d /mnt/chia-harvester/final/ > /mnt/cache/log/$date-\$\$.log" &
#fi
pid=$!
logid=$!
#ps aux | grep "chia "
#ps aux | grep "chia " | grep $pid
#echo $pid $logid
#sleep 10
#echo load log pid=$pid logid=$logid
#echo "/mnt/chia-script/chia-reload-cache.sh $pid /mnt/chia-script/log/$date-$logid.log"
#ionice -c 3 -p $pid
sleep 10
#taskset -c $numa_node sh /mnt/chia-script/chia-reload-cache.sh $pid "/mnt/cache/log/$date-$logid.log" $numa_node &>/mnt/chia-script/nohup-log/$date-$logid.log &
nice -20 sh /mnt/chia-script/chia-reload-cache.sh $pid "/mnt/cache/log/$date-$logid.log" "0-15" &>/mnt/chia-script/nohup-log/$date-$logid.log &

sleep 60

#if [ "$is_test_copy_final" = "1" ]; then
  #taskset -c $numa_node bash /mnt/chia-script/chia-copy-final.sh $pid
  nice -20 bash /mnt/chia-script/chia-copy-final.sh $pid
#fi

wait

rm -f /mnt/cache/log/$date-$logid.log
