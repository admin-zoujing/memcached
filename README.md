# memcached

linux下命令：memcached -d -m 2048 -l 192.168.10.224 -p 11211 -u root


Memcache概述：
Memcache是一个高性能的分布式的内存对象缓存系统，通过在内存里维护一个统一的巨大的hash表，它能够用来存储各种格式的数据，包括图像、视频、文件以及数据库检索的结果等。简单的说就是将数据调用到内存中，然后从内存中读取，从而大大提高读取速度。

Memcached是以守护程序方式运行于一个或多个服务器中，随时会接收客户端的连接和操作。
 
Memcache安装：
1:下载libevent与memcache软件包。
 libevent下载地址：http://monkey.org/~provos/libevent/
 memcache下载地址:http://memcached.org/

chmod -R 777 /usr/local/src/memcached
#时间时区同步，修改主机名
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ntpdate cn.pool.ntp.org
hwclock --systohc
echo "*/30 * * * * root ntpdate -s 3.cn.poop.ntp.org" >> /etc/crontab

sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/selinux/config
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/selinux/config
sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/sysconfig/selinux 
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/sysconfig/selinux
setenforce 0 && systemctl stop firewalld && systemctl disable firewalld 

rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid
yum -y install gcc* make cmake autoconf libtool
 
#安装libevent
mkdir -p /usr/local/memcached/libevent
cd /usr/local/src/memcached/
tar -zxvf libevent-2.0.21-stable.tar.gz -C /usr/local/memcached/libevent
cd /usr/local/memcached/libevent/libevent-2.0.21-stable
./configure -prefix=/usr/local/memcached/libevent
make && make install
echo '/usr/local/memcached/libevent/lib' > /etc/ld.so.conf.d/libevent.conf
ldconfig 


#安装memcached-1.4.15
cd /usr/local/src/memcached/
tar -zxvf memcached-1.4.15.tar.gz -C /usr/local/memcached/
cd /usr/local/memcached/memcached-1.4.15/
./configure --prefix=/usr/local/memcached/ --with-libevent=/usr/local/memcached/libevent
make && make install

cat >> /usr/local/memcached.conf <<EOF
PORT="11211"
USER="root"
MAXCONN="2048"
CACHESIZE="2048"
OPTIONS=""
EOF

#开启memcache，并连接测试：以守护进程模式启动memcached
#/usr/local/memcached/bin/memcached -d -l 192.168.8.20 -p 11211 -m 2048 -u root
#服务随机启动
#echo '/usr/local/memcached/bin/memcached -d -l 192.168.8.20 -p 11211 -m 2048 -u root' >> /etc/rc.local 

cat >> /usr/lib/systemd/system/memcached.service <<EOF
[Unit]
Description=Memcached
Before=httpd.service tomcat.service 
After=network.target

[Service]
Type=simple
EnvironmentFile=/usr/local/memcached.conf
ExecStart=/usr/local/memcached/bin/memcached -u \$USER -p \$PORT -m \$CACHESIZE -c \$MAXCONN \$OPTIONS

[Install]
WantedBy=multi-user.target
EOF
systemctl enable memcached.service && systemctl start memcached.service && systemctl stop memcached.service && systemctl restart memcached.service

cd
rm -rf /usr/local/src/memcached
ps aux |grep memcached

#查看状态 #ps -ef | grep 11211
          #cat /tmp/memcached.pid
          #kill `cat /tmp/memcached.pid`


查看memcache是否开启：
客户端连接测试（使用telnet）
#telnet192.168.8.20 11211能连接上，说明memcache成功启用，可使用stats命令查看当前状态
#stats（只能telnet登录使用）
STAT pid 29563
STAT uptime 228
STAT time 1377137834
STAT version 1.4.15
STAT libevent 2.1.3-alpha
STAT pointer_size 64
STAT rusage_user 0.000999
STAT rusage_system 0.000999
STAT curr_connections 5
STAT total_connections 6
STAT connection_structures 6
STAT reserved_fds 20
STAT cmd_get 0
STAT cmd_set 0
STAT cmd_flush 0
STAT cmd_touch 0
STAT get_hits 0
STAT get_misses 0
STAT delete_misses 0
STAT delete_hits 0
STAT incr_misses 0
STAT incr_hits 0
STAT decr_misses 0
STAT decr_hits 0
STAT cas_misses 0
STAT cas_hits 0
STAT cas_badval 0
STAT touch_hits 0
STAT touch_misses 0
STAT auth_cmds 0
STAT auth_errors 0
STAT bytes_read 7
STAT bytes_written 0
STAT limit_maxbytes 2147483648
STAT accepting_conns 1
STAT listen_disabled_num 0
STAT threads 4
STAT conn_yields 0
STAT hash_power_level 16
STAT hash_bytes 524288
STAT hash_is_expanding 0
STAT bytes 0
STAT curr_items 0
STAT total_items 0
STAT expired_unfetched 0
STAT evicted_unfetched 0
STAT evictions 0
STAT reclaimed 0
END
© 2019 GitHub, Inc.
Terms
Privacy
Security
Status
Help
Contact GitHub
Pricing
API
Training
Blog
About
