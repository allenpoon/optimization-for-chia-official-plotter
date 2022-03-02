# Optimization for Chia official plotter

## Introduction
These scripts are designed to optimize using slow HDD drive as temp drive. As SSD is expensive and have lifespan problem. It need to take time to turn off plotting and replace defeated SSD. As a result, it lose ~2x plotting time. By using HDD, the downtime is overcome. But the problem is HDD random read and write is much slower than SSD. These script are designed to boost HDD performance by chaning the random read to sequencial read. HDD performance will boost to >150MB/s which is much faster than its random read ~1MB/s. SATA SSD will become just 3x faster than HDD.
These script will auto start new chia plotting after previous plotting completed specific phase. And Also resolved network crowded problem when plotter copying the final file to destination

## Getting Start
You need to spend lots of time for tuning the script as the script is only optimized for my machine. So you need to know familiar with shell script. You can: 
1. disabled NUMA optimization by editing [plot-machine/get_next_numa.sh](plot-machine/get_next_numa.sh)
    * replace ```sed "${next_numa_node}!d"``` to ```head -1```
1. disabled copy final optimization by editing [plot-machine/chia-create-plot.sh](plot-machine/chia-create-plot.sh)
1. go through [os_operation_notes.md](os_operation_notes.md)
1. try to start plotting in 1 HDD
1. tune the script by tracking disk and cpu usage
    * ```dstat -d -D sda,sdb,sdc```
    * ```top```

## For your reference

### Plotter Resource usage
 * If you create 1 plot
   * Memory allocation is 40G + plotter(usually 5GB) (~10 mins within whole plot, at phase 2 table 7)
   * Memory allocation is 20G + plotter(usually 5GB) (20% of whole plot times, at phase 2)
   * Memory allocation is 6G + plotter(usually 5GB)
 * If you create many plots in parallel, you can use average memory usage to calculate total memory you need.
   * But if the spare memory is too low, the cache hit ratio will become low. In worst case, the script will always request HDD for cache, which will slow down the average plot time
 * If you use 1TB HDD, it can be start 3 parallel instance maximum but sometime will slow down

### Hardware Configuration
 * CPU: Intel Xeon L5520 x 2
 * RAM: DDR3 REG ECC 16GB * 12
 * Storage: 2TB HDD x 2 for plot, 1TB HDD x 3 for plot, 128GB SSD for boot and docker

In this configuration, I can create, in average, 14 plots per days with 12 parallel plotting
3 parallel plots for 2TB HDD, 2 parallel plots for 1TB HDD

### Tuning Direction
 1. How much different between L5520 and your CPU?
    * If your single core of your CPU is 1.5x faster than L5520, your hdd may be creating 2 or 1 in parallel
    * If your single core of your CPU is 3x up faster than L5520, you may need to consider combine 2 or more HDD in RAID 0
    * Combine all HDD into 1 RAID 0 may be good idea but iops will give you higher lantency which may make you cache request and write request get jam
 1. How much memory you have?

### Tips for tuning
If you are using faster CPU, you may
 * decrease number of parallel plots in each HDD
 * combine 2 or more HDD as RAID 0 with >500GB HDD for 1 plot (increase throughput)
 * Find or write new File System which can
   * Combine multiple HDD into 1 HDD
   * Files in that file system will be **RANDOMLY** distribute into one of the HDD **WITHOUT** striping
   * JBOD may be the most similiar to this requirement by it is not randomly distribute into HDD. So no performance gain.

**OLD** 1TB HDD may be better 

If you find this script is helping you. You can support me with XCH ```xch1x3amyj00tqr0d2xrfvn6h408hvveh95rq3dwye379cq8rtufx7pqtu82vx```