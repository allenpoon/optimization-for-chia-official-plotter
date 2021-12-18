if [ "$1" = "" ]; then
  is_exist=$(ps aux | grep run-queue | grep "\(evict\|cache\)")
  if [ "$is_exist" != "" ]; then
    exit
  fi

  # setup
  mkdir /mnt/cache/chia-evict /mnt/cache/chia-cache-long /mnt/cache/chia-cache-p1-short /mnt/cache/chia-cache-p3-short /mnt/cache/chia-cache-final 2>/dev/null
  sleep 1
  nohup $0 kill-dead 2>/dev/null >/dev/null &
  nohup $0 evict 2>/dev/null >/dev/null &
  nohup $0 cache 2>/dev/null >/dev/null &
else
  # runtime
  target=$1
  if [ "$target" = "kill-dead" ]; then
    while :; do
      kill -9 $(ps -eo pid,comm,etime | grep vmtouch | grep -v " 00:" | awk '{print $1}')
      sleep 120
    done
  elif [ "$target" = "evict" ]; then
    while :; do
      file_list=$(ls /mnt/cache/chia-evict/* 2>/dev/null)
      if [ "$file_list" != "" ]; then
        for f in $file_list; do
          ionice -c 3 sh $f
        done
      fi
      if [ "$file_list" != "" ]; then
        rm -f $file_list
      fi
  
      sh -c "sleep 30"
    done
  else
    total_state=12
    counter=0
    is_work=0
    file_list_final_counter=1
    file_list_p3_table7_counter=1
    file_list_p3_p2_counter=1
    file_list_p3_p3_counter=1
    file_list_p3_p3s_counter=1
    file_list_p1_counter=1
    file_list_p2_counter=1
    file_list_final_wait_counter=999
    file_list_p3_table7_wait_counter=999
    file_list_p3_p2_wait_counter=999
    file_list_p3_p3_wait_counter=999
    file_list_p3_p3s_wait_counter=999
    file_list_p1_wait_counter=999
    file_list_p2_wait_counter=999
    while :; do
      f=""
      if [ "$counter" = "0" ] || [ "$counter" = "1" ]; then
        f=$(echo "$file_list_final" | awk "{print \$$file_list_final_counter}" | grep -v '*')
        if [ -z "$f" ]; then
          f=""
          file_list_final_counter=1
          file_list_final=$(echo /mnt/cache/chia-cache-final/*)
        else
          file_list_final_counter=$(($file_list_final_counter + 1))
        fi
      elif [ "$counter" = "2" ]; then
        f=$(echo "$file_list_p3_table7" | awk "{print \$$file_list_p3_table7_counter}" | grep -v '*')
        if [ -z "$f" ]; then
          f=""
          file_list_p3_table7_counter=1
          file_list_p3_table7=$(echo /mnt/cache/chia-cache-p3-short/*table7*)
        else
          file_list_p3_table7_counter=$(($file_list_p3_table7_counter + 1))
        fi
      elif [ "$counter" = "3" ] || [ "$counter" = "7" ]; then
        f=$(echo "$file_list_p3_p2" | awk "{print \$$file_list_p3_p2_counter}" | grep -v '*')
        if [ -z "$f" ]; then
          f=""
          file_list_p3_p2_counter=1
          file_list_p3_p2=$(echo /mnt/cache/chia-cache-p3-short/*.p2.*)
        else
          file_list_p3_p2_counter=$(($file_list_p3_p2_counter + 1))
        fi
      elif [ "$counter" = "4" ] || [ "$counter" = "8" ]; then
        f=$(echo "$file_list_p3_p3" | awk "{print \$$file_list_p3_p3_counter}" | grep -v '*')
        if [ -z "$f" ]; then
          f=""
          file_list_p3_p3_counter=1
          file_list_p3_p3=$(echo /mnt/cache/chia-cache-p3-short/*.p3.*)
        else
          file_list_p3_p3_counter=$(($file_list_p3_p3_counter + 1))
        fi
      elif [ "$counter" = "5" ] || [ "$counter" = "9" ]; then
        f=$(echo "$file_list_p3_p3s" | awk "{print \$$file_list_p3_p3s_counter}" | grep -v '*')
        if [ -z "$f" ]; then
          f=""
          file_list_p3_p3s_counter=1
          file_list_p3_p3s=$(echo /mnt/cache/chia-cache-p3-short/*.p3s.*)
        else
          file_list_p3_p3s_counter=$(($file_list_p3_p3s_counter + 1))
        fi
      elif [ "$counter" = "6" ] || [ "$counter" = "10" ]; then
        f=$(echo "$file_list_p1" | awk "{print \$$file_list_p1_counter}" | grep -v '*')
        if [ -z "$f" ]; then
          f=""
          file_list_p1_counter=1
          file_list_p1=$(echo /mnt/cache/chia-cache-p1-short/*)
        else
          file_list_p1_counter=$(($file_list_p1_counter + 1))
        fi
      elif [ "$counter" = "11" ]; then
        f=$(echo "$file_list_p2" | awk "{print \$$file_list_p2_counter}" | grep -v '*')
        if [ -z "$f" ]; then
          f=""
          file_list_p2_counter=1
          file_list_p2=$(echo /mnt/cache/chia-cache-long/*)
        else
          file_list_p2_counter=$(($file_list_p2_counter + 1))
        fi
      fi

      if [ -n "$f" ]; then
        is_work=1
        echo -n $f
        START=$(date +%s)
        ionice -c 1 -n 2 sh $f
        END=$(date +%s)
        rm $f
        echo ""
        DIFF=$(echo "$END - $START" | bc)
        echo "Loading Time: ${DIFF}s"
        if [ "$DIFF" -le "2" ]; then
          continue
        fi
      fi

      counter=$(($counter + 1))
      if [ "$counter" -ge "$total_state" ]; then
        if [ "$is_work" = "0" ]; then
          echo No work pending, Sleep 20s
          sleep 20
        fi
        is_work=0
        counter=0
      fi
    done
  fi
fi
