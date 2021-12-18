shopt -s expand_aliases
alias cnf1="sed 's/\/mnt\/\(chia-farmer\|chia-harvester\)\/\(tmp\|final\)\/plot-k3[2-9]-[0-9]\{4\}\(-[0-9]\{2\}\)\{4\}-\([0-9a-f]\{2\}\)[0-9a-f]\{60\}\([0-9a-f]\{2\}\).plot/\4\5/g'"
alias cnf2="sed 's/sort_bucket_//g'"
alias cnf3="sed 's/\.tmp//g'"

pid=$1

phase=0

tmp_tmp_path=$(ls -l /proc/$pid/fd | grep /mnt | grep '.plot.2.tmp' | awk '{print $11}' | head -1)
#tmp_tmp_path='/mnt/chia-farmer/tmp/plot-k32-2021-08-06-10-29-df3dd2ae6c29ea955b7a03f46126037d0a9a0cccaccc1331140f23ca4b6bf329.plot.2.tmp'
#tmp_final_path=$(echo $tmp_tmp_path | sed 's/chia-farmer\/tmp/chia-harvester\/final/' | sed 's/.plot.2.tmp/.plot/')
tmp_final_path=$(echo $tmp_tmp_path | sed 's/.plot.2.tmp/.plot/')

final_tmp_path=$(echo $tmp_tmp_path | sed 's/chia-farmer\/tmp/chia-harvester\/final/').working
final_final_path=$(echo $final_tmp_path | sed 's/.plot.2.tmp.working/.check.plot/')

block_max_p3=10
block_max_p4=2
block_min=$([ "$block_max_p3" -gt "$block_max_p4" ] && echo "$block_max_p4" || echo "$block_max_p3")
echo $block_min
bs=134217728
prev99_size=$(ls -l $final_tmp_path | awk '{print $5}')
if [ "$prev99_size" = "" ]; then
  prev99_size=0
fi
prev99_block=$(echo "$prev99_size / $bs" | bc)
prev8_block=$prev99_block
prev7_block=$prev99_block
prev6_block=$prev99_block
prev5_block=$prev99_block
prev4_block=$prev99_block
prev3_block=$prev99_block
prev2_block=$prev99_block
prev1_block=$prev99_block
curr0_block=$prev99_block
next1_block=0
next2_block=0
touch $final_tmp_path
# inotifywait -m $tmp_tmp_path -e modify |
  while true; do
    echo "enter loop"
#    read -t 20 path
#    echo "clearing ongoing change logs"
#    while read -t 5 a; do true; done;
#    echo "cleared ongoing change logs"
    inotifywait -t 240 $tmp_tmp_path -e modify
    echo sleep for 10 second
    sleep 10

    next2_size=$(ls -l $tmp_tmp_path 2>/dev/null | awk '{print $5}')
    if [ "$next2_size" = "" ]; then
      next2_size=0
    fi

    if [ "$phase" != "4" ]; then
      check_result=$(/mnt/chia-script/chia-check-phase.sh /mnt/cache/log/*-${pid}.log)
      phase=$(echo $check_result | awk '{print $1}')
      if [ "$phase" = "4" ]; then
        # first time phase 4
        sleep 40
      fi
    fi
    echo "Phase $phase"
    if [ "$phase" = "4" ]; then
      echo entering sleep mode
      sleep 15
      echo exit sleep mode
    fi
    next2_block=$(echo "$next2_size / $bs" | bc)
    block_diff=$( echo "$next2_block - $curr0_block" | bc )
    if [ "$block_diff" -gt "$block_min" ]; then
      if [ "$phase" = "4" ]; then
        if [ "$block_diff" -gt "$block_max_p4" ]; then
          next1_block=$( echo "$curr0_block + $block_max_p4" | bc )
          echo 1_1 Modify next1_block=$next1_block
        else
          next1_block=$next2_block
        fi
      elif [ "$block_diff" -gt "$block_max_p3" ]; then
        next1_block=$( echo "$curr0_block + $block_max_p3" | bc )
        echo 2_1 Modify next1_block=$next1_block
      else
        next1_block=$next2_block
      fi
    else
      next1_block=$next2_block
    fi
    if [ "$(ps aux | awk '{print $2}' | grep $pid | grep -v grep)" = "" ]; then
      kill $(ps aux | grep "inotifywait" | grep "$tmp_tmp_path" | awk '{print $2}')
      break
    fi
    if [ "$curr0_block" -ne "$next1_block" ]; then
      copy_count=$( echo "$curr0_block - $prev99_block" | bc )
#      copy_count=$( echo "$prev1_block - $prev99_block" | bc )
#      copy_count=$( echo "$prev2_block - $prev99_block" | bc )
#      copy_count=$( echo "$prev3_block - $prev99_block" | bc )
#      copy_count=$( echo "$prev4_block - $prev99_block" | bc )
#      copy_count=$( echo "$prev5_block - $prev99_block" | bc )
#      copy_count=$( echo "$prev6_block - $prev99_block" | bc )
#      copy_count=$( echo "$prev7_block - $prev99_block" | bc )
#      copy_count=$( echo "$prev8_block - $prev99_block" | bc )
      if [ "$copy_count" -gt "0" ]; then
        echo dd conv=notrunc bs=$bs skip=$prev99_block seek=$prev99_block count=$copy_count if=$tmp_tmp_path of=$final_tmp_path
        dd conv=notrunc bs=$bs skip=$prev99_block seek=$prev99_block count=$copy_count if=$tmp_tmp_path of=$final_tmp_path
      fi

      # get final size
      prev99_size=$(ls -l $final_tmp_path | awk '{print $5}')
      prev99_block=$(echo "$prev99_size / $bs" | bc)

      prev8_block=$prev7_block
      prev7_block=$prev6_block
      prev6_block=$prev5_block
      prev5_block=$prev4_block
      prev4_block=$prev3_block
      prev3_block=$prev2_block
      prev2_block=$prev1_block
      prev1_block=$curr0_block
      curr0_block=$next1_block
      echo Copied $prev99_size
      /mnt/chia-script/add-queue.sh chia-evict "f-$(echo $tmp_tmp_path | cnf1 | cnf2 | cnf3)" "vmtouch -eq -p -$prev4_size $tmp_tmp_path" &
      /mnt/chia-script/add-queue.sh chia-evict "h-$(echo $final_tmp_path | cnf1 | cnf2 | cnf3)" "vmtouch -eq $final_tmp_path" &
    fi
  done
echo Plot create process end

# check size
echo $tmp_final_path $final_tmp_path
tmp_size=$(ls -l $tmp_final_path | head -1 | awk '{print $5}')
final_size=$(ls -l $final_tmp_path | head -1 | awk '{print $5}')
final_block=$(echo "$final_size / $bs" | bc)

echo tmp_size=$tmp_size final_size=$final_size
if [ "$tmp_size" -ne "$final_size" ]; then
  echo dd conv=notrunc bs=$bs skip=$final_block seek=$final_block if=$tmp_final_path of=$final_tmp_path
  dd conv=notrunc bs=$bs skip=$final_block seek=$final_block if=$tmp_final_path of=$final_tmp_path
fi
echo dd file size completed
echo dd bs=256 count=1 conv=notrunc if=$tmp_final_path of=$final_tmp_path
dd bs=256 count=1 conv=notrunc if=$tmp_final_path of=$final_tmp_path
echo dd patch completed
mv $final_tmp_path $final_final_path
final_final_name=$(echo $final_final_path | sed 's/\/mnt\/chia-harvester\/final\///')
echo "ssh allen@192.168.100.242 sudo ./check_plots.sh $final_final_name"
check_result=$(ssh allen@192.168.100.242 sudo ./check_plots.sh $final_final_name)
if [ "$check_result" = "0" ]; then
  echo check fail

  final_size=$(ls -l $final_final_path | head -1 | awk '{print $5}')
  final_block=$(echo "$final_size / $bs" | bc)

  prev_block=""
  current_block=$( echo "$final_block - 10" | bc )

  dd conv=notrunc bs=$bs skip=$current_block seek=$current_block if=$tmp_final_path of=$final_final_path
  echo "ssh allen@192.168.100.242 sudo ./check_plots.sh $final_final_name"
  check_result=$(ssh allen@192.168.100.242 sudo ./check_plots.sh $final_final_name)
  if [ "$check_result" = "0" ]; then
    while [ "$current_block" -ge 0 ]; do
      prev_block=$current_block
      current_block=$( echo "$current_block - 10" | bc )
      dd conv=notrunc bs=$bs skip=$current_block seek=$current_block count=10 if=$tmp_final_path of=${final_final_path}
      echo "ssh allen@192.168.100.242 sudo ./check_plots.sh $final_final_name"
      check_result=$(ssh allen@192.168.100.242 sudo ./check_plots.sh $final_final_name)
      echo $check_result
      if [ "$check_result" = "1" ]; then
        break
      fi
    done
  fi
  mv $final_final_path ${final_final_path}.fail_check.plot
else
  echo check ok
fi

rm -f $tmp_final_path
echo end script
