if [ "$1" != "" ]; then
  if [ "$(/usr/local/bin/docker exec -t chia-harvester-250 chia plots check -g $1 | grep '1 valid plots')" = "" ]; then
    echo 0
  else
    echo 1
  fi
else
  echo 0
fi
