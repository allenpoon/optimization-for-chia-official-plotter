alias cnf1="sed 's/\/mnt\/\(chia-farmer\|chia-harvester\)\/\(tmp\|final\)\/plot-k3[2-9]-[0-9]\{4\}\(-[0-9]\{2\}\)\{4\}-\([0-9a-f]\{2\}\)[0-9a-f]\{60\}\([0-9a-f]\{2\}\).plot/\4\5/g'"
alias cnf2="sed 's/sort_bucket_//g'"
alias cnf3="sed 's/\.tmp//g'"

#is_test_copy_final=$(/chia-blockchain/miner_config.sh is_test_copy_final 2>/dev/null)

counter=0
pid=$1
numa_node=$3
if [ "$numa_node" = "" ]; then
  numa_node=$(lscpu | grep "On-line" | awk '{print $4}')
fi
while [ "$counter" -le "36" ]
do
  check_result=$(/mnt/chia-script/chia-check-phase.sh $2)
  phase=$(echo $check_result | awk '{print $1}' | tr -d '\r')
  progress=$(echo $check_result | awk '{print $2}' | tr -d '\r')
  bucket=$(echo $check_result | awk '{print $3}' | tr -d '\r')
  computation_phase=$(echo $check_result | awk '{print $4}' | tr -d '\r')
  if [ "$phase" -eq "1" ]; then
    if [ "$(($counter % 3))" -eq 0 ]; then
      if [ "$progress" != "1" ]; then
        p1_2_cache_list_old=$p1_2_cache_list
        p1_2_cache_tmp=$(ls -l /proc/$pid/fd | grep /mnt | grep -P 'p1.t\d.sort_bucket' | awk '{print $11}')
        if [ "$p1_2_cache_tmp" != "" ]; then
          p1_2_cache_list=$(ls -l $p1_2_cache_tmp | awk '{print $9}' | head -1)
        fi
        if [ "$p1_2_cache_list" != "" ]; then
          #if [ "$(($counter % 2))" -eq 0 ] || [ "$p1_2_cache_list_old" != "$p1_2_cache_list" ]; then
          p1_2_cache_curr_id="$(echo $p1_2_cache_list | grep -oP "\d{3}.tmp")"
          p1_2_cache_next_id="$( printf "%03d" $(($(echo $p1_2_cache_curr_id | grep -oP "\d{3}" | sed 's/^0*//') + 1)) ).tmp"
          p1_2_cache_nex2_id="$( printf "%03d" $(($(echo $p1_2_cache_next_id | grep -oP "\d{3}" | sed 's/^0*//') + 1)) ).tmp"
          p1_2_cache_list_patch="$p1_2_cache_list $(echo $p1_2_cache_list | sed "s/sort_bucket_$p1_2_cache_curr_id/sort_bucket_$p1_2_cache_next_id/g") $(echo $p1_2_cache_list | sed "s/sort_bucket_$p1_2_cache_curr_id/sort_bucket_$p1_2_cache_nex2_id/g")"
          # echo caching $p1_2_cache_list_patch | cnf1 | cnf2 | cnf3
          for f in $p1_2_cache_list_patch; do
            /mnt/chia-script/add-queue.sh chia-cache-p1-short "$(echo $f | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -tq $f" &
          done
        fi
      fi
    fi

    if [ "$counter" -eq "0" ]; then
      p1_1_cache_clear_list=""
      p1_1_cache_clear_tmp=$(ls -l /proc/$pid/fd | grep /mnt | grep 'table[^7]' | awk '{print $11}' | head -1)
      if [ "$p1_1_cache_clear_tmp" != "" ]; then
        p1_1_cache_clear_list=$(ls $(echo $p1_1_cache_clear_tmp | sed 's/table[1-7].*/table*/') | grep -v table7)
        p1_1_cache_clear_table7=$(ls $(echo $p1_1_cache_clear_tmp | sed 's/table[1-7].*/table*/') | grep table7)
      fi
      # echo evicting $p1_1_cache_clear_list | cnf1 | cnf2 | cnf3
      for f in $p1_1_cache_clear_list; do
        /mnt/chia-script/add-queue.sh chia-evict "$(echo $f | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq $f" &
      done
      /mnt/chia-script/add-queue.sh chia-evict "$(echo $p1_1_cache_clear_table7 | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq -p 20G- $p1_1_cache_clear_table7" &

      if [ "$progress" -le "6" ]; then
        p1_3_cache_clear_list_old=$p1_3_cache_clear_list
        p1_3_cache_clear_tmp=$(ls -l /proc/$pid/fd | grep /mnt | grep "p1.t${progress}.sort_bucket" | awk '{print $11}')
        if [ "$p1_3_cache_clear_tmp" != "" ]; then
          p1_3_cache_clear_list=$(ls -l $p1_3_cache_clear_tmp | tail -n +5 | awk '{print $9}')
        fi
        if [ "$p1_3_cache_clear_list" != "" ]; then
          # echo evicting  $p1_3_cache_clear_list | cnf1 | cnf2 | cnf3
          for f in $p1_3_cache_clear_list; do
              /mnt/chia-script/add-queue.sh chia-evict "$(echo $f | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq $f" &
          done
        fi
      fi
    fi
  fi


  if [ "$phase" -eq "2" ] || ([ "$phase" -eq "3" ] && [ "$progress" -eq "1" ]); then
    p2_cache_list_old=$p2_cache_list
    p2_cache_list=$(ls -l $(ls -l /proc/$pid/fd | grep /mnt | grep -P 'table\d.tmp' | awk '{print $11}') | awk '{print $9}' | head -1)
    if [ "$p2_cache_list_old" != ""  ] && [ "$p2_cache_list_old" != "$p2_cache_list" ];then
      exit
    fi

    if [ "$counter" = "0" ]; then
      if [ "$p2_cache_list" != "" ]; then
        if [ "$progress" = "7" ]; then
          p2_remove_target_tmp=$(ls $(echo $p2_cache_list | sed 's/table[1-7].*/table7*/'))
          p2_remove_target=$(ls /mnt/cache/chia-evict/$(echo $p2_remove_target_tmp | cnf1 | cnf2 | cnf3)* 2>/dev/null)
          if [ "$p2_remove_target" ]; then
            rm -f $p2_remove_target
          fi
        elif [ "$progress" = "6" ]; then
          p2_cache_table7=$(ls $(echo $p2_cache_list | sed 's/table[1-7].*/table7*/'))
          # echo evicting $p2_cache_table7 | cnf1 | cnf2 | cnf3
          for f in $p2_cache_table7; do
            /mnt/chia-script/add-queue.sh chia-evict "$(echo $f | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq $f" &
          done
        fi

        p2_remove_target_tmp=$(echo $p2_cache_list | sed "s/table[1-7]/table$(($progress+1))/")
        p2_remove_target=$(ls /mnt/cache/chia-cache-long/$(echo $p2_remove_target_tmp | cnf1 | cnf2 | cnf3)* 2>/dev/null)
        if [ "$p2_remove_target" ]; then
          rm -f $p2_remove_target    
        fi

        p2_cache_target=$(echo $p2_cache_list | sed "s/table[1-7]/table${progress}/")
        size=$(ls -lh $p2_cache_target | awk '{print $5}')
        size_no_unit=$(echo $size | sed 's/G//')
        if [ "$size_no_unit" != "0" ]; then
          /mnt/chia-script/add-queue.sh chia-cache-long "$(echo $p2_cache_target | cnf1 | cnf2 | cnf3).00G-01G" "taskset -c $numa_node vmtouch -tq -p -1.1G $p2_cache_target" &
          from=1
          to=2
          while [ "$to" -lt "$size_no_unit" ]
          do
            /mnt/chia-script/add-queue.sh chia-cache-long "$(echo $p2_cache_target | cnf1 | cnf2 | cnf3).$(printf "%02d" ${from})G-$(printf "%02d" ${to})G" "taskset -c $numa_node vmtouch -tq -p ${from}G-${to}.1G $p2_cache_target" &
            from=$to
            to=$(($to+1))           
          done
          /mnt/chia-script/add-queue.sh chia-cache-long "$(echo $p2_cache_target | cnf1 | cnf2 | cnf3).$(printf "%02d" ${from})G-" "taskset -c $numa_node vmtouch -tq -p ${from}G- $p2_cache_target" &
        fi

        if [ "$phase" -eq "2" ]; then
          p2_2_cache_clear_list_old=$p2_2_cache_clear_list
          p2_2_cache_clear_tmp=$(ls -l /proc/$pid/fd | grep /mnt | grep "table7" | awk '{print $11}' | head -1)
          if [ "$p2_2_cache_clear_tmp" != "" ]; then
            p2_2_cache_clear_list="$(ls $(echo $p2_2_cache_clear_tmp | sed "s/table7*/p2.t${progress}*/") 2>/dev/null)"
          fi

          if [ "$p2_2_cache_clear_list" != "" ]; then
            # echo evicting  $p2_2_cache_clear_list | cnf1 | cnf2 | cnf3
            for f in $p2_2_cache_clear_list; do
              /mnt/chia-script/add-queue.sh chia-evict "$(echo $f | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq $f" &
            done
          fi
        fi
      fi
    fi
  fi
  if [ "$phase" -eq "3" ] || [ "$phase" -eq "4" ]; then
    if [ "$(($counter % 3))" -eq 0 ]; then
      p3_3_cache_list_old=$p3_3_cache_list
      p3_3_cache_tmp=$(ls -l /proc/$pid/fd | grep /mnt | grep 'table7' | awk '{print $11}' | head -1)
      p3_3_cache_curr_bucket=$(printf "%03d" $bucket)
      p3_3_cache_next_bucket=$(printf "%03d" $(($bucket+1)))
      p3_3_cache_nex2_bucket=$(printf "%03d" $(($bucket+2)))
      p3_3_cache_target_curr=""
      p3_3_cache_target_next=""
      p3_3_cache_target_nex2=""
      p3_3_evict_target=""
      if [ "$computation_phase" -eq "1" ]; then
        p3_3_cache_target_curr="$(echo $p3_3_cache_tmp | sed "s/table7/p3s.t${progress}.sort_bucket_${p3_3_cache_curr_bucket}/") $(echo $p3_3_cache_tmp | sed "s/table7/p2.t$(($progress+1)).sort_bucket_${p3_3_cache_curr_bucket}/")"
        p3_3_cache_target_next="$(echo $p3_3_cache_tmp | sed "s/table7/p3s.t${progress}.sort_bucket_${p3_3_cache_next_bucket}/") $(echo $p3_3_cache_tmp | sed "s/table7/p2.t$(($progress+1)).sort_bucket_${p3_3_cache_next_bucket}/")"
        p3_3_cache_target_nex2="$(echo $p3_3_cache_tmp | sed "s/table7/p3s.t${progress}.sort_bucket_${p3_3_cache_nex2_bucket}/") $(echo $p3_3_cache_tmp | sed "s/table7/p2.t$(($progress+1)).sort_bucket_${p3_3_cache_nex2_bucket}/")"
        p3_3_evict_target="$(echo $p3_3_cache_tmp | sed "s/table7/p3.t$(($progress+1)).sort_bucket_*/")"
      elif [ "$computation_phase" -eq "2" ]; then
        p3_3_cache_target_curr="$(echo $p3_3_cache_tmp | sed "s/table7/p3.t$(($progress+1)).sort_bucket_${p3_3_cache_curr_bucket}/")"
        p3_3_cache_target_next="$(echo $p3_3_cache_tmp | sed "s/table7/p3.t$(($progress+1)).sort_bucket_${p3_3_cache_next_bucket}/")"
        p3_3_cache_target_nex2="$(echo $p3_3_cache_tmp | sed "s/table7/p3.t$(($progress+1)).sort_bucket_${p3_3_cache_nex2_bucket}/")"
        p3_3_evict_target="$(echo $p3_3_cache_tmp | sed "s/table7/p3s.t$(($progress+1)).sort_bucket_*/")"
      fi
      p3_3_cache_list=$(ls $p3_3_cache_target_curr $p3_3_cache_target_next $p3_3_cache_target_nex2 2>/dev/null | grep /mnt)
      p3_3_evict_list=$(ls $p3_3_evict_target 2>/dev/null | grep /mnt | tail -n +5)
  
      if [ "$p3_3_cache_list" != "" ]; then
        #if [ "$(($counter % 2))" -eq 0 ] || [ "$p3_3_cache_list_old" != "$p3_3_cache_list" ]; then
        # echo caching $p3_3_cache_list | cnf1 | cnf2 | cnf3
        for f in $p3_3_cache_list; do
          rm -f /mnt/cache/chia-evict/$(echo $f | cnf1 | cnf2 | cnf3)
          /mnt/chia-script/add-queue.sh chia-cache-p3-short "$(echo $f | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -tq $f" &
        done
      fi
    fi


    if [ "$counter" -eq 0 ]; then
      if [ "$p3_3_evict_list" != "" ]; then
        # echo caching $p3_3_cache_list | cnf1 | cnf2 | cnf3
        for f in $p3_3_evict_list; do
          /mnt/chia-script/add-queue.sh chia-evict "$(echo $f | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq $f" &
        done
      fi
    fi


    if [ "$phase" -eq "3" ] && [ "$progress" -eq "6" ]; then
      p3_4_cache_list_old=$p3_4_cache_list
      p3_4_cache_list=$(ls -l /proc/$pid/fd | grep /mnt | grep 'table7' | awk '{print $11}' | head -1)

      if [ "$computation_phase" -eq "1" ]; then
        p3_4_cache_size=$(ls -lh $p3_4_cache_list | awk '{print $5}')
        p3_4_cache_size_no_unit=$(echo $p3_4_cache_size | sed 's/G//')
        p3_4_evict_start_GB=""
        p3_4_cache_start_GB=""
        p3_4_cache_end_GB=""
        if [ "$bucket" -gt "1" ]; then
          p3_4_evict_start_GB="$(echo "scale=2; ($bucket - 1) * $p3_4_cache_size_no_unit / 111" | bc)G"
        fi
        if [ "$bucket" -gt "1" ]; then
          p3_4_cache_start_GB="$(echo "scale=2; ($bucket - 1) * $p3_4_cache_size_no_unit / 111" | bc)G"
        fi
        if [ "$bucket" -lt "109" ]; then
          p3_4_cache_end_GB="$(echo "scale=2; ($bucket + 2) * $p3_4_cache_size_no_unit / 111" | bc)G"
        fi

        if [ "$p3_4_cache_list" != "" ]; then
          is_same=$(ls "*$(echo $p3_4_cache_list | cnf1 | cnf2 | cnf3).$p3_4_cache_start_GB-$p3_4_cache_end_GB*")
          if [ "$is_same" = "" ]; then
            rm -f /mnt/cache/chia-cache-p3-short/$(echo $p3_4_cache_list | cnf1 | cnf2 | cnf3)*
            # echo caching $p3_4_cache_list $p3_4_cache_start_GB-$p3_4_cache_end_GB | cnf1 | cnf2 | cnf3
            /mnt/chia-script/add-queue.sh chia-cache-p3-short "$(echo $p3_4_cache_list | cnf1 | cnf2 | cnf3).$p3_4_cache_start_GB-$p3_4_cache_end_GB" "taskset -c $numa_node vmtouch -tq -p $p3_4_cache_start_GB-$p3_4_cache_end_GB $p3_4_cache_list" &
            # echo evicting $p3_4_cache_list -$p3_4_cache_start_GB | cnf1 | cnf2 | cnf3
            if [ "$(($counter % 4))" -eq "0" ]; then
              /mnt/chia-script/add-queue.sh chia-evict "$(echo $p3_4_cache_list | cnf1 | cnf2 | cnf3).-$p3_4_evict_start_GB" "taskset -c $numa_node vmtouch -eq -p -$p3_4_evict_start_GB $p3_4_cache_list" &
              # /mnt/chia-script/add-queue.sh chia-evict "$(echo $p3_4_cache_list | cnf1 | cnf2 | cnf3).-$p3_4_evict_start_GB" "taskset -c $numa_node vmtouch -eq -p -$p3_4_evict_start_GB $p3_4_cache_list" &
            fi
          fi
        fi
      elif [ "$computation_phase" -eq "2" ] && [ "$counter" -eq "0" ]; then
        # echo evicting $p3_4_cache_list | cnf1 | cnf2 | cnf3
        /mnt/chia-script/add-queue.sh chia-evict "$(echo $p3_4_cache_list | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq $p3_4_cache_list" &
      fi
    fi
    #if [ "$is_test_copy_final" != "1" ]; then
    #  p3_5_cache_list_old=$p3_5_cache_list
    #  p3_5_cache_list=$(ls -l /proc/$pid/fd | grep /mnt | grep '\.2\.tmp' | awk '{print $11}')
    #  if [ "$p3_5_cache_list" != "" ] && [ "$counter" -eq "0" ]; then
    #    # echo evicting $p3_5_cache_list | cnf1 | cnf2 | cnf3
    #    for f in $p3_5_cache_list; do
    #      /mnt/chia-script/add-queue.sh chia-evict "$(echo $f | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq $f" &
    #    done
    #  fi
    #fi
  fi

  if [ "$phase" -eq "5" ]; then
    p5_cache_copy_from_old=$p5_cache_list
    p5_cache_copy_from_result=$(ls -l /proc/$pid/fd | grep /mnt/chia-fa | grep '\.2\.tmp')
    if [ "$p5_cache_copy_from_result" != "" ]; then
      p5_cache_copy_to_result=$(ls -l /proc/$pid/fd | grep /mnt/chia-ha | grep '\.2\.tmp')
      p5_cache_copy_from=$(echo $p5_cache_copy_from_result | awk '{print $11}')
      p5_cache_copy_to=$(echo $p5_cache_copy_to_result | awk '{print $11}')
      p5_cache_copy_total=$(ls -l $p5_cache_copy_from | awk '{print $5}')
      if [ "$p5_cache_copy_to" != "0" ]; then
        p5_cache_copy_progress=$(ls -l $p5_cache_copy_to | awk '{print $5}')
      else
        p5_cache_copy_progress=0
      fi
      # echo evicting $p5_cache_list | cnf1 | cnf2 | cnf3
      echo $p5_cache_copy_progress/$p5_cache_copy_total
      rm -f /mnt/cache/chia-cache-final/*
      /mnt/chia-script/add-queue.sh chia-cache-final "farmer-1-evict-$(echo $p5_cache_copy_from | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq -p -$p5_cache_copy_progress $p5_cache_copy_from" &
      /mnt/chia-script/add-queue.sh chia-cache-final "farmer-2-cache-$p5_cache_copy_progress-$(($p5_cache_copy_progress+1000000000))-$(echo $p5_cache_copy_from | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -tq -p $p5_cache_copy_progress-$(($p5_cache_copy_progress+1000000000)) $p5_cache_copy_from" &
      /mnt/chia-script/add-queue.sh chia-evict "harvester-evict-$(echo $p5_cache_copy_to | cnf1 | cnf2 | cnf3)" "taskset -c $numa_node vmtouch -eq -p -$p5_cache_copy_progress $p5_cache_copy_to" &
    fi
  fi

  if [ "$phase" -eq "6" ]; then
    exit
  fi

  counter=$(($counter + 1))
  sleep 10
done

