shopt -s expand_aliases
alias cnf1="sed 's/\/mnt\/\(chia-farmer\|chia-harvester\)\/\(tmp\|final\)\/plot-k3[2-9]-[0-9]\{4\}\(-[0-9]\{2\}\)\{4\}-\([0-9a-f]\{2\}\)[0-9a-f]\{60\}\([0-9a-f]\{2\}\).plot/\4\5/g'"
alias cnf2="sed 's/sort_bucket_//g'"
alias cnf3="sed 's/\.tmp//g'"

#tmp_tmp_path=$(ls -l /proc/$pid/fd | grep /mnt | grep '.plot.2.tmp' | awk '{print $11}' | head -1)
#tmp_tmp_path='/mnt/chia-farmer/tmp/plot-k32-2021-08-06-10-29-df3dd2ae6c29ea955b7a03f46126037d0a9a0cccaccc1331140f23ca4b6bf329.plot.2.tmp'
#tmp_final_path=$(echo $tmp_tmp_path | sed 's/chia-farmer\/tmp/chia-harvester\/final/' | sed 's/.plot.2.tmp/.plot/')
#tmp_final_path=$(echo $tmp_tmp_path | sed 's/.plot.2.tmp/.plot/')
tmp_final_path=$1

final_tmp_path=$(echo $tmp_final_path | sed 's/chia-farmer\/tmp/chia-harvester\/final/').2.tmp.working
final_final_path=$(echo $final_tmp_path | sed 's/.plot.2.tmp.working/.check.plot/')

bs=134217728

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
