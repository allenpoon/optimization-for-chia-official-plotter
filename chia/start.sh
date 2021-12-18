if [ "$1" = "" ]; then
  nohup sh /mnt/chia-script/start.sh in-background 2>/dev/null >/dev/null &
else
  /mnt/chia-script/container-init.sh

  loop=0
  while [ "$(sh /mnt/chia-script/is-run.sh 2>/dev/null)" = "1" ];
  do
    if [ "$(sh /mnt/chia-script/chia-can-start.sh 2>/dev/null)" = "1" ];
    then
      echo [hihihi] $(sh /mnt/chia-script/chia-can-start.sh 2>/dev/null)
      nohup sh /mnt/chia-script/chia-create-plot.sh 2>/dev/null >/dev/null &
    fi
    sleep 30
    sh /mnt/chia-script/flush-cache.sh $loop
    loop=$(($loop + 1))
    if [ "$loop" = "1000000" ]; then
      loop=0
    fi
  done
fi
