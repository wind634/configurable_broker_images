#####redis集群实现方式有点复杂。
#####除haproxy外，主要有三种角色：哨兵、M节点，R节点
#####主从节点的配置一致(主从的区别是redis-server带的参数-slaveof)，哨兵节点的配置要独立出来。
#####三种不同的配置: haproxy, redis-master/slave, redis-sentinel