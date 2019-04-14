#! /bin/bash
#centos7.4 memcached-1.5.12安装脚本
#libevent下载地址：http://monkey.org/~provos/libevent/     memcache下载地址:http://memcached.org/
sourceinstall=/usr/local/src/memcached
chmod -R 777 $sourceinstall
#时间时区同步，修改主机名
ntpdate  ntp1.aliyun.com
hwclock --systohc
echo "*/30 * * * * root ntpdate -s  ntp1.aliyun.com" >> /etc/crontab

#sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/selinux/config
#sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/selinux/config
#sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/sysconfig/selinux 
#sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/sysconfig/selinux
#setenforce 0 && systemctl stop firewalld && systemctl disable firewalld 

rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid
yum -y install gcc* make cmake autoconf libtool

#安装libevent
mkdir -p /usr/local/memcached/libevent
cd $sourceinstall
tar -zxvf libevent-2.0.21-stable.tar.gz -C /usr/local/memcached/libevent
cd /usr/local/memcached/libevent/libevent-2.0.21-stable
./configure -prefix=/usr/local/memcached/libevent
make && make install
echo 'export PATH=/usr/local/memcached/libevent/bin/:/usr/local/memcached/libevent/sbin:$PATH' >> /etc/profile.d/libevent.sh
mkdir -pv /usr/include/memcached/libevent
ln -sv /usr/local/memcached/libevent/include /usr/include/memcached/libevent
echo '/usr/local/memcached/libevent/lib' >> /etc/ld.so.conf.d/libevent.conf
ldconfig 
echo 'MANPATH /usr/local/memcached/libevent/man' >> /etc/man.config

#安装memcached-1.5.12
cd $sourceinstall
tar -zxvf memcached-1.5.12.tar.gz -C /usr/local/memcached/
cd /usr/local/memcached/memcached-1.5.12/
./configure --prefix=/usr/local/memcached/ --with-libevent=/usr/local/memcached/libevent
make && make install
echo 'export PATH=/usr/local/memcached/bin/:/usr/local/memcached/sbin:$PATH' >> /etc/profile.d/libevent.sh
ln -sv /usr/local/memcached/include /usr/include/memcached
echo '/usr/local/memcached/lib' >> /etc/ld.so.conf.d/memcached.conf
ldconfig 
echo 'MANPATH /usr/local/memcached/man' >> /etc/man.config

groupadd memcached
useradd -g memcached memcached -s /sbin/nologin

cat >> /usr/local/memcached/memcached.conf <<EOF
PORT="11211"
USER="memcached"
MAXCONN="2048"
CACHESIZE="64"
OPTIONS=""
EOF

#开启memcache，并连接测试：以守护进程模式启动memcached
#/usr/local/memcached/bin/memcached -d -l `ifconfig|grep 'inet'|head -1|awk '{print $2}'|cut -d: -f2` -p 11211 -m 2048 -u root
#服务随机启动
#echo '/usr/local/memcached/bin/memcached -d -l `ifconfig|grep 'inet'|head -1|awk '{print $2}'|cut -d: -f2` -p 11211 -m 2048 -u root' >> /etc/rc.local 

cat >> /usr/lib/systemd/system/memcached.service <<EOF
[Unit]
Description=Memcached
Before=httpd.service tomcat.service php.service
After=network.target

[Service]
Type=simple
EnvironmentFile=/usr/local/memcached/memcached.conf
ExecStart=/usr/local/memcached/bin/memcached -u \$USER -p \$PORT -m \$CACHESIZE -c \$MAXCONN \$OPTIONS

[Install]
WantedBy=multi-user.target
EOF
chown -R memcached:memcached /usr/local/memcached
systemctl enable memcached.service 
systemctl start memcached.service 
systemctl stop memcached.service 
systemctl restart memcached.service

cd
rm -rf /usr/local/src/memcached
ps aux |grep memcached

firewall-cmd --permanent --zone=public --add-port=11211/tcp --permanent
firewall-cmd --permanent --query-port=11211/tcp
firewall-cmd --reload

#查看状态 #ps -ef | grep 11211
          #cat /tmp/memcached.pid
          #kill `cat /tmp/memcached.pid`

#memcached数据导出: memcached-tool 127.0.0.1:11211 dump > data.txt
#memcached数据导入: yum -y install nc && nc 127.0.0.1 11211 < data.txt  
#说明：进入数据库查看数据，结果是get不到，是因为data.txt的数据有一个时间戳已经过期    
#修改data.txt文件数据的时间戳(说明：修改为1个小时后的时间戳) date -d "+1 hour" +%s 
#vim data.txt 
#telnet连接:telnet 192.168.50.110 11211 (stats items //列出所有keys) (stats cachedump 7 0 //通过id=7获取key值 0表示全部)

#三、使用libmemcached的客户端工具:（C/C++代码）
#官网下载：http://libmemcached.org/libMemcached.html
#下载地址：https://launchpad.net/libmemcached/1.0/1.0.16/+download/libmemcached-1.0.16.tar.gz
#1) 编译安装libmemcached
# cd /usr/local/src/memcached/
# mkdir -p /usr/local/memcached/libmemcached
# tar -zxvf libmemcached-1.0.18.tar.gz -C /usr/local/memcached/libmemcached
# cd /usr/local/memcached/libmemcached/libmemcached-1.0.18/
# ./configure -prefix=/usr/local/memcached/libmemcached --with-memcached --enable-memslap  
# make && make install
# ldconfig
#2) 客户端工具
# memcp test --servers=127.0.0.1:11211
# memcat test--servers=127.0.0.1:11211 
# memping 
# memslap
# memstat


#四、安装Memcached的PHP扩展（php）
#############################php和memcached一体安装（省略）##############################################
#############################php和memcached一体安装（省略）##############################################
#(1)下载地址：http://pecl.php.net/package/memcache
#php安装
# yum -y install epel-release.noarch 
# yum -y groupinstall "Desktop Platform Development" 
# yum -y install gcc bzip2-devel libmcrypt-devel libxml2 libxml2-devel.x86_64 
# useradd php -s /sbin/nologin
# mkdir -p /usr/local/php
# cd /usr/local/src/memcached/php_session/
# tar xf php-5.5.38.tar.bz2 -C /usr/local/php/
# cd /usr/local/php/php-5.5.38/
# export LD_LIBRARY_PATH=/usr/local/libgd/lib
# ./configure --prefix=/usr/local/php/ --with-config-file-path=/usr/local/php/etc
# make && make test && make intall
# rm -rf /etc/php.ini
# ln -s /usr/local/php/etc/php.ini /etc/php.ini
# cp -rpf php.ini-production /usr/local/php/etc/php.ini
# cp -rpf /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
# ln -s /usr/local/php/etc/php-fpm.conf /etc/php-fpm.conf
# sed -i 's|;pid = run/php-fpm.pid|pid = run/php-fpm.pid|' /usr/local/php/etc/php-fpm.conf
# sed -i 's|user = nobody|user = php|' /usr/local/php/etc/php-fpm.conf
# sed -i 's|group = nobody|group = php|' /usr/local/php/etc/php-fpm.conf
# cat >> /usr/lib/systemd/system/php-fpm.service <<EOF
# [Unit] 
# Description=php-fpm 
# After=network.target

# [Service] 
# Type=simple
# PIDFile=/run/php-fpm.pid
# ExecStart=/usr/local/php/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php/etc/php-fpm.conf
# ExecStop=/bin/kill -SIGINT \$MAINPID
# ExecReload=/bin/kill -USR2 \$MAINPID
# PrivateTmp=true

# [Install] 
# WantedBy=multi-user.target
# EOF
# chmod 755 /usr/lib/systemd/system/php-fpm.service
# systemctl daemon-reload && systemctl enable php-fpm.service && systemctl restart php-fpm.service


# cd /usr/local/src/memcached/php_session/
# mkdir -pv /usr/local/memcached/
# tar -zxvf memcached-2.2.0.tgz -C /usr/local/memcached
# cd /usr/local/memcached/memcached-2.2.0/
# /usr/local/php/bin/phpize 
# ./configure --prefix=/usr/local/memcached/ --with-libevent=/usr/local/memcached/libevent --with-php-config=/usr/local/php/bin/php-config --enable-memcached
# make && make install

#编辑/usr/local/php/lib/php.ini，在“动态模块”相关的位置添加如下一行来载入memcache扩展：
# extension=/usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/memcache.so
# sed -i 's|extension = memcache.so|extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/memcache.so|' /usr/local/php/lib/php.ini
# systemctl daemon-reload && systemctl restart php-fpm.service 
#对memcached功能进行测试，在网站目录中建立测试页面test.php，添加如下内容：如果有输出“Hello World is from memcached.”等信息，则表明memcache已经能够正常工作。
# <?php
# $mem = new Memcache;
# $mem->connect("127.0.0.1", 11211)  or die("Could not connect");

# $version = $mem->getVersion();
# echo "Server's version: ".$version."<br/>\n";

# $mem->set('hellokey', 'Hello World', 0, 600) or die("Failed to save data at the memcached server");
# echo "Store data in the cache (data will expire in 600 seconds)<br/>\n";

# $get_result = $mem->get('hellokey');
# echo "$get_result is from memcached server.";         
# ?>
#############################php和memcached一体安装（省略）###############################################
#############################php和memcached一体安装（省略）###############################################


###############################已经安装好php和memcached后#########################################
#(2)下载地址：http://pecl.php.net/package/memcache
#①安装PHP的memcache扩展
# cd /usr/local/src/memcached/php_session/
# tar -zxvf memcache-2.2.7.tgz -C /usr/local/memcached/
# cd /usr/local/memcached/memcache-2.2.7/
# /usr/local/php/bin/phpize
# ./configure --prefix=/usr/local/memcached/ --with-libevent=/usr/local/memcached/libevent --with-php-config=/usr/local/php/bin/php-config --enable-memcache
# make && make install

#上述安装完后提示：Installing shared extensions:   /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/

#②编辑/usr/local/php/etc/php.ini，在“动态模块”相关的位置添加如下一行来载入memcache扩展：
# echo "extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/memcache.so" >> /usr/local/php/etc/php.ini 


#而后对memcached功能进行测试，在网站目录中建立测试页面test.php，添加如下内容：
# <?php
# $mem = new Memcache;
# $mem->connect("127.0.0.1", 11211)  or die("Could not connect");

# $version = $mem->getVersion();
# echo "Server's version: ".$version."<br/>\n";

# $mem->set('hellokey', 'Hello World', 0, 600) or die("Failed to save data at the memcached server");
# echo "Store data in the cache (data will expire in 600 seconds)<br/>\n";

# $get_result = $mem->get('hellokey');
# echo "$get_result is from memcached server.";         
# ?>

# systemctl daemon-reload && systemctl restart php-fpm.service 
# 如果有输出“Hello World is from memcached.”等信息，则表明memcache已经能够正常工作。


###############################已经安装好php和memcached后session配置###########################################
#################编辑php.ini添加两行待测试）##########################
##  session.save_handler = memcache                                ##
##  session.save_path = "tcp://192.168.122.130:11211"              ##
#################或者httpd.conf中对应的虚拟主机中添加#################
##  php_value session.save_handler "memcache"                      ##
##  php_value session.save_path "tcp://192.168.122.130:11211"      ##
################或者php-fpm.conf对应的pool中添加######################
##  php_value[session.save_handler] = memcache                     ##
##  php_value[session.save_path] = "tcp://192.168.122.130:11211 "  ##
#####################################################################
#一、配置php将会话保存至memcached中
#编辑/usr/local/php/etc/php.ini 文件，确保如下两个参数的值分别如下所示：
#session.save_handler = memcache
#session.save_path = "tcp://172.16.200.11:11211?persistent=1&weight=1&timeout=1&retry_interval=15"

# sed -i 's|session.save_handler = files|session.save_handler = memcache|' /usr/local/php/etc/php.ini 
# sed -i '/session.save_handler = memcache/a\session.save_path = "tcp://192.168.8.110:11211?persistent=1&weight=1&timeout=1&retry_interval=15"' /usr/local/php/etc/php.ini 


#二、测试（新建php页面setsess.php，为客户端设置启用session：）
# <?php
# session_start();
# if (!isset($_SESSION['www.MageEdu.com'])) {
#   $_SESSION['www.MageEdu.com'] = time();
# }
# print $_SESSION['www.MageEdu.com'];
# print "<br><br>";
# print "Session ID: " . session_id();
# ?>

#（新建php页面showsess.php，获取当前用户的会话ID：）
# <?php
# session_start();
# $memcache_obj = new Memcache;
# $memcache_obj->connect('192.168.8.110', 11211);
# $mysess=session_id();
# var_dump($memcache_obj->get($mysess));
# $memcache_obj->close();
# ?>


#五、Nginx整合memcached:
#server {
#        listen       80;
#        server_name  www.magedu.com;
#        #charset koi8-r;
#        #access_log  logs/host.access.log  main;
#        location / {
#                set $memcached_key $uri;
#                memcached_pass     127.0.0.1:11211;
#                default_type       text/html;
#                error_page         404 @fallback;
#        }
#        location @fallback {
#                proxy_pass http://172.16.0.1;
#        }
#}

#六、安装memadmin
#cd /usr/local/src/memcached/php_session/
#wget  http://www.junopen.com/memadmin/memadmin-1.0.12.tar.gz
#tar -zxvf memadmin-1.0.12.tar.gz -C /usr/local/nginx/html/php/
#/usr/local/nginx/html/php/memadmin/config.php设置user 和password，然后即可在远端访问了。
#http://192.168.8.110/php/memadmin/


