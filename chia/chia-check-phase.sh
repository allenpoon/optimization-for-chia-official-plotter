keyword="$(tail -n 400 $1 | grep -v Bucket | grep -v Total | tac)"

if [ "$(echo "$keyword" | grep "Renamed final file from" | head -1)" != "" ]; then
  echo 6
elif [ "$(echo "$keyword" | grep "Time for phase 4" | head -1)" != "" ]; then
  # completed phase 4
  echo 5
elif [ "$(echo "$keyword" | grep "Time for phase 3" | head -1 )" != "" ]; then
  # completed phase 3, entering phase 4
  keyword_tmp="$(tail -n 10 $1 | grep "Bucket" | tac | head -1 | awk '{print $2}' | tr -d '\r')"
  echo 4 7 $keyword_tmp 1
elif [ "$(echo "$keyword" | grep "Compressing" | head -1 )" != "" ]; then
  keyword_tmp="$(tail -n 10 $1 | grep "Bucket" | tac | head -1 | awk '{print $2}' | tr -d '\r')"
  computation_phase_is_first_computation="$(tail -n 200 $1 | grep computation | tac | head -1 | grep Second)"
  computation_phase_is_second_computation="$(tail -n 200 $1 | grep computation | tac | head -1 | grep First)"
  if [ "$computation_phase_is_second_computation" != "" ] ; then
    computation_phase=2
  else
    computation_phase=1
  fi
  echo 3 $(echo "$keyword" | grep "Compressing" | head -1 | awk '{print $3}' | tr -d '\r') $keyword_tmp $computation_phase
elif [ "$(echo "$keyword" | grep "Backpropagating"  | head -1 )" != "" ]; then
  keyword_tmp="$(echo "$keyword" | grep "Backpropagating"  | head -1 | awk '{print $4}' | tr -d '\r')"
  computation_phase_is_first_computation="$(tail -n 200 $1 | grep time | tac | head -1 | grep sort)"
  computation_phase_is_second_computation="$(tail -n 200 $1 | grep time | tac | head -1 | grep scanned)"
  if [ "$keyword_tmp" = "7" ]; then
    computation_phase=1
  elif [ "$keyword_tmp" = "6" ]; then
    is_last_2_scanned="$(tail -n 200 $1 | grep time | tac | head -2 | grep scanned)"
    if [ "$is_last_2_scanned" = "" ]; then
      computation_phase=1
    else
      computation_phase=2
    fi 
  elif [ "$computation_phase_is_second_computation" != "" ] ; then
    computation_phase=2
  else
    computation_phase=1
  fi
  echo 2 $keyword_tmp 0 $computation_phase
elif [ "$(echo "$keyword" | grep Forward | head -1)" != "" ]; then
  keyword_tmp="$(tail -n 10 $1 | grep "Bucket" | tac | head -1 | awk '{print $2}' | tr -d '\r')"
  echo 1 $(echo "$keyword" | grep "Computing" | head -1 | awk '{print $3}' | tr -d '\r') $keyword_tmp
elif [ "$(echo "$keyword" | grep "Starting plotting progress into temporary dirs")" != "" ]; then
  echo 1 1 0
else
  echo 0
fi

