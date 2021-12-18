dir=$(dirname $0)
next_numa_node=$(cat ${dir}/next_numa_node)
if [ "$next_numa_node" = 1 ]; then
  echo 2 >"${dir}/next_numa_node"
else
  echo 1 >"${dir}/next_numa_node"
fi
lscpu | grep NUMA | grep "CPU(s)" | awk '{print $4}' | sed "${next_numa_node}!d"
