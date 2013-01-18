=============
Swarmstorage
=============

Overview
===========

Swarmstorage is an open source CADOS(Content Addressable Distributed Object Storage) written in google golang, distributed with BSD license.

Current status
==============

Currently swarmstorage is runnable and is under heavy development. 
All administrate toolkit and dashboard are not in developing yet.
The status is post prototype, but far before product release.

Please don't use it in production environment.

What
===========

Swarmstorage is designed to be the cloud storage backend residing in datacenter, serving huge amount of data objects with minimal effort of maintainance. 

Objects are content addressable, such as immutable files, images and any others, accessed by their hash values, without any metadata such as filenames, permissions, dates etc.

Client can access swarmstorage by two RESTful methods(read and write) to any node of the domain.

With current ordinary hardware, one swarmstorage domain can scale to several thousands of nodes, serve data over 100 PB. If network connectivity allows, the domain can scale larger without notable performance degradation. Object size can range from 10KB to over 10TB without notable performance degradation. 

Why
===========

There are many distributed storage systems already:

  - Distributed file systems: google GFS, Amazon S3, Hadoop HDFS, Ceph, Lustre, Venti, MogileFS, Moosefs and much more.  
  - Distributed NoSQL systems: Dynamo, Cassandra, Voledmort, MongoDB etc. 

AFAIK, most of them need central meta server(s) or name server(s) to manage file allocation, which is always the performance bottleneck, or even become single point of failure. That greatly limit the scalability and availability of a cluster, and make it hard to maintain a big cluster.

Some of them provide full POSIX semantics as a normal file system. These additional specifications provide support for convenient usage, but need a lot of effort to implement and make the whole system much complicate.

As describe in [CAP theorem](http://en.wikipedia.org/wiki/CAP_theorem), it is impossible for a distributed computer system to simultaneously provide all three of the following guarantees: Consistency, Availability and Partition tolerance. Most of current distributed systems include consensus protocols(Paxos or vector clock) to solve consistence problem, while trying to provide Availability and Partition tolerance. That slow down the system very much, and makes the protocol very complicate.

Swarmstorage is trying to solve above problems by provide a highly scalable, available and maintainable high performance distributed storage system.

How
===========

Decentralized
--------------

Swarmstorage is completely decentralized and peer to peer. The only role in swarmstorage domain is smart data node, which is capable of:

  - discover the domain
  - gossip with other nodes
  - serve data access
  - rebalance data

The whole system is consist of many of these smart and autonomous nodes, discovering unknown region, cooperating with each other, works like a [swarm](http://en.wikipedia.org/wiki/Swarm_intelligence).

Distributed
--------------

Block is the basic storage component in swarmstorage, which is referenced by its hash(sha1) value. If the size of object below some limit(default 8 MB), object is saved in one block directly. Otherwise, object is split into many blocks(default size 4 MB), and create an index block which content is the component block hashes to identify the object. 

A domain is consist of nodes, each node owns many storage devices. A node is identified by one of its IP address. A storage device is usually a physical disk, identified by an unique ID(usually an UUID generated by administrator when initiate the device). 

The domain map is the map of all nodes and their devices in the domain. By discovering unknown region, new node can join the domain without manual assistance. By gossip with other nodes, all nodes in the domain will eventually achieve the perspective of the whole domain. 

[Consistent hash](http://en.wikipedia.org/wiki/Consistent_hashing) or [distributed hash table(DHT)](http://en.wikipedia.org/wiki/Distributed_hash_table) is used to determine the location of block, and is calculated by devices IDs of the domain map. Each device have many(depend on device weight) virtual ticks on the hash ring. By locate block hash on the ring, a block can be located on a specified device, hence on a specified node. That tick is called primary tick. A block is replicated to three different nodes. The other two replica nodes are nodes adjacent of the primary tick.

One of the biggest benefit of consistent hash is that it limit the impact of partial changes of node, avoid incurring the system wide impaction. Add or remove a device will only affect adjacent devices on the ring.

Another benefit is the invariable of virtual ticks of a device. That allows the partial perspective of domain map works the same as comprehensive perspective for local blocks locating, just requiring correlate nodes are consensus of the partial perspective, which can be achieved easily. Without the requirement of consensus of comprehensive perspective of domain, there is no necessary to have a coordinator to maintain the domain map and notify all nodes to update it. Otherwise, as the domain scales out, the frequency of updating will grow fast, eventually out of the capability of the coordinator, and will impact all nodes' performance for updating.

CAP
--------------

As a [content addressable storage](http://en.wikipedia.org/wiki/Content-addressable_storage) system, swarmstorage reference block by its hash value. For each block stored on node, the content is self consistent. There is no necessary to use consensus protocols to solve consistence problem. That is a very big advantage for a distributed system. Swarmstorage can provide the best Availability and Partition tolerance without impacting performance.

Simplified
--------------

Swarmstorage does not provide full POSIX semantics, which greatly simplify the structure of the system. Client can only access swarmstorage like a key-value system with the limit that the key is object hash. This is compliant with the design purpose, being a underlying massive storage system. Upper layer application can easily expand to provide most POSIX semantics.

There is only two methods for client to access data: read object and write object. No delete method is provided. The reason is to achieve completely consistent in a distributed system. Besides keeping block content consistent, block state is also need to be kept consistent. The approach is to keep data monotone increasing, thus all data operations are idempotent and consistent.

A toolkit will be provided to compact storage by removing obsolete blocks. This operation requires comprehensive information of all blocks and their relationship, thus is an upper level intelligence above single node, and should only be carried out by administrator manually.

Performance
--------------

Every node can serve client access, the access pressure can spread out evenly over whole domain. 

Swarmstorage is pure peer to peer, the main traffic of a specified node is fixed and limited among correlate nodes. The overall performance can be increased linearly as domain scales out.

Maintainance
--------------

Consistent hash depend on devices only. The purpose of maintain device independently is for more smooth the maintainance. In a fairly scale domain, devices can be moved independently among nodes without incurring data migration. This is surely useful to recovery quickly from nodes failure.

Dashboard
--------------

Every node expose APIs for administrator to monitor the node status and issue administrate tasks. 

A domain dashboard will be provided to:

  - monitor status of all nodes
  - alert exceptions
  - analysis overall performance
  - adjust settings
  - execute common maintainance tasks, such as add and remove nodes and devices

More details
============

For more details, see doc in the source code.


Install
===========

build
-----------

    go build -o /tmp/swarm cmd/swarm/*.go


Setup
===========

Suppose nodebase path is /data/swarm.

swarm
-----------

1. Prepare node base::

    swarm nodeinit --nodebase /data/swarm  
    Edit /data/swarm/conf/node.ini
    Optional copy domain.ini to /data/swarm/conf/domain.ini and edit

2. Add devices::

    Mount disk as /data/swarm/devices/device1  
    swarm deviceinit --nodebase /data/swarm --device device1

3. Add another devices::

    Mount disk as /data/swarm/devices/device2  
    swarm deviceinit --nodebase /data/swarm --device device2

4. Start swarm daemon::

    swarm daemonize swarm serve -nodebase /data/swarm


