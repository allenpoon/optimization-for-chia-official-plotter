# Plotter Host
## Setup script
```
sudo bash

yum install -y yum-utils

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y epel-release
yum install -y iotop nfs-utils rsync wget docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker
```

## disable swap
```
nano /etc/fstab
swapoff -a
```

## format disk
```
mkfs.xfs -m crc=0 -f /dev/sdb
mkfs.xfs -m crc=0 -f /dev/sdc
mkfs.xfs -m crc=0 -f /dev/sdd
mkfs.xfs -m crc=0 -f /dev/sde
mkfs.xfs -m crc=0 -f /dev/sdf
mkdir /mnt/tmp-disk-0
mkdir /mnt/tmp-disk-1
mkdir /mnt/tmp-disk-2
mkdir /mnt/tmp-disk-3
mkdir /mnt/tmp-disk-4
```

## Mount disk
```
mount 192.168.100.242:/volume1/chia/ /mnt/chia-harvester/
mount -o async,noatime,nobarrier,nodiratime,noikeep,allocsize=268435456,largeio,logbufs=8,logbsize=256k,swalloc /dev/sdb /mnt/tmp-disk-0
mount -o async,noatime,nobarrier,nodiratime,noikeep,allocsize=268435456,largeio,logbufs=8,logbsize=256k,swalloc /dev/sdc /mnt/tmp-disk-1
mount -o async,noatime,nobarrier,nodiratime,noikeep,allocsize=268435456,largeio,logbufs=8,logbsize=256k,swalloc /dev/sdd /mnt/tmp-disk-2
mount -o async,noatime,nobarrier,nodiratime,noikeep,allocsize=268435456,largeio,logbufs=8,logbsize=256k,swalloc /dev/sde /mnt/tmp-disk-3
mount -o async,noatime,nobarrier,nodiratime,noikeep,allocsize=268435456,largeio,logbufs=8,logbsize=256k,swalloc /dev/sdf /mnt/tmp-disk-4
```

## Disk optimization
```
echo 131072 > /sys/block/sdb/queue/read_ahead_kb
echo 131072 > /sys/block/sdc/queue/read_ahead_kb
echo 131072 > /sys/block/sdd/queue/read_ahead_kb
echo 131072 > /sys/block/sde/queue/read_ahead_kb
echo 131072 > /sys/block/sdf/queue/read_ahead_kb

echo 512 > /sys/block/sdb/queue/nr_requests
echo 512 > /sys/block/sdc/queue/nr_requests
echo 512 > /sys/block/sdd/queue/nr_requests
echo 512 > /sys/block/sde/queue/nr_requests
echo 512 > /sys/block/sdf/queue/nr_requests

echo 4096 > /sys/block/sdb/queue/iosched/fifo_batch
echo 4096 > /sys/block/sdc/queue/iosched/fifo_batch
echo 4096 > /sys/block/sdd/queue/iosched/fifo_batch
echo 4096 > /sys/block/sde/queue/iosched/fifo_batch
echo 4096 > /sys/block/sdf/queue/iosched/fifo_batch

echo 2 > /sys/block/sdb/queue/iosched/writes_starved
echo 2 > /sys/block/sdc/queue/iosched/writes_starved
echo 2 > /sys/block/sdd/queue/iosched/writes_starved
echo 2 > /sys/block/sde/queue/iosched/writes_starved
echo 2 > /sys/block/sdf/queue/iosched/writes_starved


echo 0 > /sys/block/sdb/queue/iosched/front_merges 
echo 0 > /sys/block/sdc/queue/iosched/front_merges 
echo 0 > /sys/block/sdd/queue/iosched/front_merges 
echo 0 > /sys/block/sde/queue/iosched/front_merges 
echo 0 > /sys/block/sdf/queue/iosched/front_merges 


echo $(( 100 )) > /sys/block/sdb/queue/iosched/write_expire
echo $(( 100 )) > /sys/block/sdc/queue/iosched/write_expire
echo $(( 100 )) > /sys/block/sdd/queue/iosched/write_expire
echo $(( 100 )) > /sys/block/sde/queue/iosched/write_expire
echo $(( 100 )) > /sys/block/sdf/queue/iosched/write_expire

echo $(( 500 )) > /sys/block/sdb/queue/iosched/read_expire
echo $(( 500 )) > /sys/block/sdc/queue/iosched/read_expire
echo $(( 500 )) > /sys/block/sdd/queue/iosched/read_expire
echo $(( 500 )) > /sys/block/sde/queue/iosched/read_expire
echo $(( 500 )) > /sys/block/sdf/queue/iosched/read_expire

echo 9 > /proc/sys/vm/dirty_background_ratio
echo 18 > /proc/sys/vm/dirty_ratio

echo $(( 60 * 100 )) > /proc/sys/vm/dirty_expire_centisecs
echo $(( 20 * 100 )) > /proc/sys/vm/dirty_writeback_centisecs

echo 30 >  /sys/class/block/sdb/bdi/max_ratio
echo 30 >  /sys/class/block/sdc/bdi/max_ratio
echo 30 >  /sys/class/block/sdd/bdi/max_ratio
echo 30 >  /sys/class/block/sde/bdi/max_ratio
echo 30 >  /sys/class/block/sdf/bdi/max_ratio
```

## Creating folder
```
mkdir /home/allen/chia
mkdir /home/allen/chia/log
mkdir /home/allen/chia/nohup-log
mkdir -p /mnt/chia-farmer/tmp
mkdir /mnt/chia-harvester
```

## Mount final folder
Remember mount final folder before create docker
```
mount 192.168.100.242:/volume1/chia/ /mnt/chia-harvester/
```

## create docker
```
docker run --privileged --name chia0 -d --mount type=tmpfs,destination=/mnt/cache,tmpfs-size=4m -v /home/allen/chia:/mnt/chia-script -v /mnt/tmp-disk-0:/mnt/chia-farmer -v /mnt/chia-harvester/final:/mnt/chia-harvester/final -e TZ="Asia/Hong_Kong" -e farmer="true" ghcr.io/chia-network/chia:latest
docker run --privileged --name chia1 -d --mount type=tmpfs,destination=/mnt/cache,tmpfs-size=4m -v /home/allen/chia:/mnt/chia-script -v /mnt/tmp-disk-1:/mnt/chia-farmer -v /mnt/chia-harvester/final:/mnt/chia-harvester/final -e TZ="Asia/Hong_Kong" -e farmer="true" ghcr.io/chia-network/chia:latest
docker run --privileged --name chia2 -d --mount type=tmpfs,destination=/mnt/cache,tmpfs-size=4m -v /home/allen/chia:/mnt/chia-script -v /mnt/tmp-disk-2:/mnt/chia-farmer -v /mnt/chia-harvester/final:/mnt/chia-harvester/final -e TZ="Asia/Hong_Kong" -e farmer="true" ghcr.io/chia-network/chia:latest
docker run --privileged --name chia3 -d --mount type=tmpfs,destination=/mnt/cache,tmpfs-size=4m -v /home/allen/chia:/mnt/chia-script -v /mnt/tmp-disk-3:/mnt/chia-farmer -v /mnt/chia-harvester/final:/mnt/chia-harvester/final -e TZ="Asia/Hong_Kong" -e farmer="true" ghcr.io/chia-network/chia:latest
docker run --privileged --name chia4 -d --mount type=tmpfs,destination=/mnt/cache,tmpfs-size=4m -v /home/allen/chia:/mnt/chia-script -v /mnt/tmp-disk-4:/mnt/chia-farmer -v /mnt/chia-harvester/final:/mnt/chia-harvester/final -e TZ="Asia/Hong_Kong" -e farmer="true" ghcr.io/chia-network/chia:latest
```

# Final dir host
## Create ssh key for chia-copy-final.sh
this is for pc which is storing final folder, chia-copy-final.sh will use ssh to call a script for checking the plot are valid or not
```
ssh-keygen
```
add id_rsa.pub to synology

## sudo no password for specific script
```
allen ALL=(ALL) NOPASSWD: /var/services/homes/allen/check_plots.sh
```

# Start chia plotting process
```
docker exec -d chia0 sh /mnt/chia-script/start.sh in-background
docker exec -d chia1 sh /mnt/chia-script/start.sh in-background
docker exec -d chia2 sh /mnt/chia-script/start.sh in-background
docker exec -d chia3 sh /mnt/chia-script/start.sh in-background
docker exec -d chia4 sh /mnt/chia-script/start.sh in-background
```

# Harvester script
```
mount 192.168.100.242:/volume1/chia/ /mnt/remote-chia/

docker stop chia-harvester-168 && docker rm chia-harvester-168
docker pull ghcr.io/chia-network/chia:latest
```

nas244
```
sudo docker run --name chia-harvester-168 -e farmer_address="192.168.100.168" -e farmer_port="8447" -e harvester="true" -e TZ="Asia/Hong_Kong" -e ca="/mnt/ca" -e keys="copy" -v /mnt/remote-chia/ssl_168/ca:/mnt/ca -v /mnt/chia/chia00:/mnt/chia/chia00 -v /mnt/chia/chia01:/mnt/chia/chia01 -v /mnt/chia/chia02:/mnt/chia/chia02 -v /mnt/chia/chia03:/mnt/chia/chia03 -v /mnt/chia/chia04:/mnt/chia/chia04 -e plots_dir="/mnt/chia/chia00:/mnt/chia/chia01:/mnt/chia/chia02:/mnt/chia/chia03:/mnt/chia/chia04" -d ghcr.io/chia-network/chia:latest 
sudo docker run --name chia-harvester-250 -e farmer_address="192.168.100.250" -e farmer_port="8447" -e harvester="true" -e TZ="Asia/Hong_Kong" -e ca="/mnt/ca" -e keys="copy" -v /mnt/remote-chia/ssl_250/ca:/mnt/ca -v /mnt/chia/chia00:/mnt/chia/chia00 -v /mnt/chia/chia01:/mnt/chia/chia01 -v /mnt/chia/chia02:/mnt/chia/chia02 -v /mnt/chia/chia03:/mnt/chia/chia03 -v /mnt/chia/chia04:/mnt/chia/chia04 -e plots_dir="/mnt/chia/chia00:/mnt/chia/chia01:/mnt/chia/chia02:/mnt/chia/chia03:/mnt/chia/chia04" -d ghcr.io/chia-network/chia:latest 
sudo docker run --name chia-harvester-005 -e farmer_address="192.168.1.5" -e farmer_port="8447" -e harvester="true" -e TZ="Asia/Hong_Kong" -e ca="/mnt/ca" -e keys="copy" -v /mnt/remote-chia/ssl_005/ca:/mnt/ca -v /mnt/chia/chia00:/mnt/chia/chia00 -v /mnt/chia/chia01:/mnt/chia/chia01 -v /mnt/chia/chia02:/mnt/chia/chia02 -v /mnt/chia/chia03:/mnt/chia/chia03 -v /mnt/chia/chia04:/mnt/chia/chia04 -e plots_dir="/mnt/chia/chia00:/mnt/chia/chia01:/mnt/chia/chia02:/mnt/chia/chia03:/mnt/chia/chia04" -d ghcr.io/chia-network/chia:latest 
```

nas243
```
sudo docker run --name chia-harvester-250 -e farmer_address="192.168.100.250" -e farmer_port="8447" -e harvester="true" -e TZ="Asia/Hong_Kong" -e ca="/mnt/ca" -e keys="copy" -v /mnt/remote-chia/ssl_250/ca:/mnt/ca -v /mnt/chia/chia00:/mnt/chia/chia00 -v /mnt/chia/chia01:/mnt/chia/chia01 -v /mnt/chia/chia02:/mnt/chia/chia02 -v /mnt/chia/chia03:/mnt/chia/chia03 -v /mnt/chia/chia04:/mnt/chia/chia04 -v /mnt/chia/chia05:/mnt/chia/chia05 -v /mnt/chia/chia06:/mnt/chia/chia06 -v /mnt/chia/chia07:/mnt/chia/chia07 -v /mnt/chia/chia08:/mnt/chia/chia08 -v /mnt/chia/chia09:/mnt/chia/chia09 -v /mnt/chia/chia10:/mnt/chia/chia10 -v /mnt/chia/chia11:/mnt/chia/chia11 -v /mnt/chia/chia12:/mnt/chia/chia12 -v /mnt/chia/chia13:/mnt/chia/chia13 -v /mnt/chia/chia14:/mnt/chia/chia14 -v /mnt/chia/chia15:/mnt/chia/chia15 -v /mnt/chia/chia16:/mnt/chia/chia16 -v /mnt/chia/chia17:/mnt/chia/chia17 -v /mnt/chia/chia18:/mnt/chia/chia18 -v /mnt/chia/chia19:/mnt/chia/chia19 -v /mnt/chia/chia20:/mnt/chia/chia20 -v /mnt/chia/chia21:/mnt/chia/chia21 -e plots_dir="/mnt/chia/chia00:/mnt/chia/chia01:/mnt/chia/chia02:/mnt/chia/chia03:/mnt/chia/chia04:/mnt/chia/chia05:/mnt/chia/chia06:/mnt/chia/chia07:/mnt/chia/chia08:/mnt/chia/chia09:/mnt/chia/chia10:/mnt/chia/chia11:/mnt/chia/chia12:/mnt/chia/chia13:/mnt/chia/chia14:/mnt/chia/chia15:/mnt/chia/chia16:/mnt/chia/chia17:/mnt/chia/chia18:/mnt/chia/chia19:/mnt/chia/chia20:/mnt/chia/chia21" -d ghcr.io/chia-network/chia:latest 
sudo docker run --name chia-harvester-168 -e farmer_address="192.168.100.168" -e farmer_port="8447" -e harvester="true" -e TZ="Asia/Hong_Kong" -e ca="/mnt/ca" -e keys="copy" -v /mnt/remote-chia/ssl_168/ca:/mnt/ca -v /mnt/chia/chia00:/mnt/chia/chia00 -v /mnt/chia/chia01:/mnt/chia/chia01 -v /mnt/chia/chia02:/mnt/chia/chia02 -v /mnt/chia/chia03:/mnt/chia/chia03 -v /mnt/chia/chia04:/mnt/chia/chia04 -v /mnt/chia/chia05:/mnt/chia/chia05 -v /mnt/chia/chia06:/mnt/chia/chia06 -v /mnt/chia/chia07:/mnt/chia/chia07 -v /mnt/chia/chia08:/mnt/chia/chia08 -v /mnt/chia/chia09:/mnt/chia/chia09 -v /mnt/chia/chia10:/mnt/chia/chia10 -v /mnt/chia/chia11:/mnt/chia/chia11 -v /mnt/chia/chia12:/mnt/chia/chia12 -v /mnt/chia/chia13:/mnt/chia/chia13 -v /mnt/chia/chia14:/mnt/chia/chia14 -v /mnt/chia/chia15:/mnt/chia/chia15 -v /mnt/chia/chia16:/mnt/chia/chia16 -v /mnt/chia/chia17:/mnt/chia/chia17 -v /mnt/chia/chia18:/mnt/chia/chia18 -v /mnt/chia/chia19:/mnt/chia/chia19 -v /mnt/chia/chia20:/mnt/chia/chia20 -v /mnt/chia/chia21:/mnt/chia/chia21 -e plots_dir="/mnt/chia/chia00:/mnt/chia/chia01:/mnt/chia/chia02:/mnt/chia/chia03:/mnt/chia/chia04:/mnt/chia/chia05:/mnt/chia/chia06:/mnt/chia/chia07:/mnt/chia/chia08:/mnt/chia/chia09:/mnt/chia/chia10:/mnt/chia/chia11:/mnt/chia/chia12:/mnt/chia/chia13:/mnt/chia/chia14:/mnt/chia/chia15:/mnt/chia/chia16:/mnt/chia/chia17:/mnt/chia/chia18:/mnt/chia/chia19:/mnt/chia/chia20:/mnt/chia/chia21" -d ghcr.io/chia-network/chia:latest 
sudo docker run --name chia-harvester-005 -e farmer_address="192.168.1.5" -e farmer_port="8447" -e harvester="true" -e TZ="Asia/Hong_Kong" -e ca="/mnt/ca" -e keys="copy" -v /mnt/remote-chia/ssl_005/ca:/mnt/ca -v /mnt/chia/chia00:/mnt/chia/chia00 -v /mnt/chia/chia01:/mnt/chia/chia01 -v /mnt/chia/chia02:/mnt/chia/chia02 -v /mnt/chia/chia03:/mnt/chia/chia03 -v /mnt/chia/chia04:/mnt/chia/chia04 -v /mnt/chia/chia05:/mnt/chia/chia05 -v /mnt/chia/chia06:/mnt/chia/chia06 -v /mnt/chia/chia07:/mnt/chia/chia07 -v /mnt/chia/chia08:/mnt/chia/chia08 -v /mnt/chia/chia09:/mnt/chia/chia09 -v /mnt/chia/chia10:/mnt/chia/chia10 -v /mnt/chia/chia11:/mnt/chia/chia11 -v /mnt/chia/chia12:/mnt/chia/chia12 -v /mnt/chia/chia13:/mnt/chia/chia13 -v /mnt/chia/chia14:/mnt/chia/chia14 -v /mnt/chia/chia15:/mnt/chia/chia15 -v /mnt/chia/chia16:/mnt/chia/chia16 -v /mnt/chia/chia17:/mnt/chia/chia17 -v /mnt/chia/chia18:/mnt/chia/chia18 -v /mnt/chia/chia19:/mnt/chia/chia19 -v /mnt/chia/chia20:/mnt/chia/chia20 -v /mnt/chia/chia21:/mnt/chia/chia21 -e plots_dir="/mnt/chia/chia00:/mnt/chia/chia01:/mnt/chia/chia02:/mnt/chia/chia03:/mnt/chia/chia04:/mnt/chia/chia05:/mnt/chia/chia06:/mnt/chia/chia07:/mnt/chia/chia08:/mnt/chia/chia09:/mnt/chia/chia10:/mnt/chia/chia11:/mnt/chia/chia12:/mnt/chia/chia13:/mnt/chia/chia14:/mnt/chia/chia15:/mnt/chia/chia16:/mnt/chia/chia17:/mnt/chia/chia18:/mnt/chia/chia19:/mnt/chia/chia20:/mnt/chia/chia21" -d ghcr.io/chia-network/chia:latest 
```

nas242
```
sudo docker run --name chia-harvester-250 -e farmer_address="192.168.100.250" -e farmer_port="8447" -e harvester="true" -e TZ="Asia/Hong_Kong" -e ca="/mnt/ca" -e keys="copy" -v /volume1/chia/ssl_250/ca:/mnt/ca -v /volume1/chia/final:/mnt/chia0 -v /volume2/chia0:/mnt/chia1 -v /volume3/chia1:/mnt/chia2 -v /volume4/chia2:/mnt/chia3 -v /volume5/chia3:/mnt/chia4 -v /volume6/chia4:/mnt/chia5 -v /volume7/chia5:/mnt/chia6 -e plots_dir="/mnt/chia0:/mnt/chia1:/mnt/chia2:/mnt/chia3:/mnt/chia4:/mnt/chia5:/mnt/chia6" -d ghcr.io/chia-network/chia:latest 
sudo docker run --name chia-harvester-168 -e farmer_address="192.168.100.168" -e farmer_port="8447" -e harvester="true" -e TZ="Asia/Hong_Kong" -e ca="/mnt/ca" -e keys="copy" -v /volume1/chia/ca:/mnt/ca -v /volume1/chia/final:/mnt/chia0 -v /volume2/chia0:/mnt/chia1 -v /volume3/chia1:/mnt/chia2 -v /volume4/chia2:/mnt/chia3 -v /volume5/chia3:/mnt/chia4 -v /volume6/chia4:/mnt/chia5 -v /volume7/chia5:/mnt/chia6 -e plots_dir="/mnt/chia0:/mnt/chia1:/mnt/chia2:/mnt/chia3:/mnt/chia4:/mnt/chia5:/mnt/chia6" -d ghcr.io/chia-network/chia:latest 
sudo docker run --name chia-harvester-005 -e farmer_address="192.168.1.5" -e farmer_port="8447" -e harvester="true" -e TZ="Asia/Hong_Kong" -e ca="/mnt/ca" -e keys="copy" -v /volume1/chia/ssl_005/ca:/mnt/ca -v /volume1/chia/final:/mnt/chia0 -v /volume2/chia0:/mnt/chia1 -v /volume3/chia1:/mnt/chia2 -v /volume4/chia2:/mnt/chia3 -v /volume5/chia3:/mnt/chia4 -v /volume6/chia4:/mnt/chia5 -v /volume7/chia5:/mnt/chia6 -e plots_dir="/mnt/chia0:/mnt/chia1:/mnt/chia2:/mnt/chia3:/mnt/chia4:/mnt/chia5:/mnt/chia6" -d ghcr.io/chia-network/chia:latest 
```

# fullnode
```
mkfs.xfs -m crc=0 -f /dev/sdb
echo 131072 > /sys/block/sdb/queue/read_ahead_kb
echo 512 > /sys/block/sdb/queue/nr_requests
echo 4096 > /sys/block/sdb/queue/iosched/fifo_batch
echo $(( 5 * 1000 )) > /sys/block/sdb/queue/iosched/write_expire
echo $(( 100 )) > /sys/block/sdb/queue/iosched/read_expire
echo $(( 60 * 100 )) > /proc/sys/vm/dirty_expire_centisecs
echo $(( 20 * 100 )) > /proc/sys/vm/dirty_writeback_centisecs
echo 20 > /proc/sys/vm/dirty_background_ratio
echo 40 > /proc/sys/vm/dirty_ratio

mkdir -p /mnt/chia
mkdir -p /mnt/chia-perm/

mount -t ramfs ramfs /mnt/chia/ -o defaults,size=128G
mount -o async,noatime,nobarrier,nodiratime,noikeep,allocsize=268435456,largeio,logbufs=8,logbsize=256k,swalloc /dev/sdb /mnt/chia-perm/

docker run --name chia -p 8444:8444 -p 8447:8447 -p 8449:8449 -e TZ="Asia/Hong_Kong" -e keys=persistent -e upnp=false -v /mnt/chia:/root/.chia -e log_level="WARNING" -d ghcr.io/chia-network/chia:latest 

docker exec -it chia chia stop -d all
docker stop chia
docker start chia
docker exec -d chia /root/.chia/script/instance_check.sh

```