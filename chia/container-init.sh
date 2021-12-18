apt install -y vmtouch bc inotify-tools rsync &

chia stop all -d &

dev=$(mount | grep chia-farmer | awk '{print $1}' | sed 's/\/dev\///')

echo $((100)) > /sys/block/$dev/queue/iosched/write_expire
echo $((500)) > /sys/block/$dev/queue/iosched/read_expire
echo 2 > /sys/block/$dev/queue/iosched/writes_starved
echo 0 > /sys/block/$dev/queue/iosched/front_merges
echo 4096 > /sys/block/$dev/queue/iosched/fifo_batch
echo 512 > /sys/block/$dev/queue/nr_requests
echo 131072 > /sys/block/$dev/queue/read_ahead_kb

mkdir -p /mnt/cache/log

wait

sh /mnt/chia-script/run-queue.sh
