num_of_instance=0
num_of_instance_in_phase1=0
num_of_instance_in_phase2=0
num_of_instance_in_phase2_lt4=0
num_of_instance_in_phase2_eq4=0
num_of_instance_in_phase2_gt4=0
num_of_instance_in_phase3=0
num_of_instance_in_phase4=0
num_of_instance_in_phase5=0

config_is_slow_hdd=$(/chia-blockchain/miner_config.sh is_slow_hdd 2>/dev/null)

for f in /mnt/cache/log/*.log;
do if [ -f "$f" ]; then
  check_result=$(/mnt/chia-script/chia-check-phase.sh $f)
  phase=$(echo $check_result | awk '{print $1}')
  progress=$(echo $check_result | awk '{print $2}')
  bucket=$(echo $check_result | awk '{print $3}')
  computation_phase=$(echo $check_result | awk '{print $4}')
  if [ "$phase" = "0" ] || [ "$phase" = "1" ]; then
    num_of_instance=$(($num_of_instance + 1))
    num_of_instance_in_phase1=$(($num_of_instance_in_phase1 + 1))
  elif [ "$phase" = "2" ]; then
    num_of_instance=$(($num_of_instance + 1))
    if [ "$progress" = "7" ]; then
      num_of_instance_in_phase1=$(($num_of_instance_in_phase1 + 1))
    else
      num_of_instance_in_phase2=$(($num_of_instance_in_phase2 + 1))
      if [ "$progress" -eq "4" ]; then
        num_of_instance_in_phase2_eq4=$(($num_of_instance_in_phase2_eq4 + 1))
      elif [ "$progress" -lt "4" ]; then
        num_of_instance_in_phase2_lt4=$(($num_of_instance_in_phase2_lt4 + 1))
      else
        num_of_instance_in_phase2_gt4=$(($num_of_instance_in_phase2_gt4 + 1))
      fi
    fi
  elif [ "$phase" = "3" ]; then
    num_of_instance=$(($num_of_instance + 1))
    if [ "$progress" = "1" ] && [ "$computation_phase" = "1" ]; then
      num_of_instance_in_phase2=$(($num_of_instance_in_phase2 + 1))
    else
      num_of_instance_in_phase3=$(($num_of_instance_in_phase3 + 1))
    fi
  elif [ "$phase" = "4" ]; then
    num_of_instance=$(($num_of_instance + 1))
    num_of_instance_in_phase4=$(($num_of_instance_in_phase4 + 1))
  elif [ "$phase" = "5" ]; then
    num_of_instance=$(($num_of_instance + 1))
    num_of_instance_in_phase5=$(($num_of_instance_in_phase5 + 1))
  fi
fi done

if [ "1" = "1" ]; then
  echo 0
elif [ "$config_is_slow_hdd" = "1" ]; then
  if [ "$(($num_of_instance - $num_of_instance_in_phase5))" -ge "2" ]; then
    echo 0
  elif [ "$(( $num_of_instance_in_phase1 + $num_of_instance_in_phase2 - $num_of_instance_in_phase2_lt4 - $num_of_instance_in_phase2_eq4))" -ge "1" ]; then
  #elif [ "$(( $num_of_instance_in_phase1 ))" -ge "1" ]; then
    echo 0
  else
    echo 1
  fi
else
  if [ "$(($num_of_instance - $num_of_instance_in_phase5))" -ge "3" ]; then
    echo 0
  elif [ "$(( $num_of_instance_in_phase1 ))" -ge "1" ]; then
    echo 0
  elif [ "$(( $num_of_instance_in_phase2 ))" -ge "2" ]; then
    echo 0
  else
    echo 1
  fi
fi
