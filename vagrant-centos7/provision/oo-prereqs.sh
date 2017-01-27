#!/bin/sh

now=$(date +"%T")
echo "Starting at : $now"

export VAGRANT_MNT="/vagrant"

echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 search api antenna opsmq daq opsdb sysdb kloopzappdb kloopzcmsdb cmsapi sensor activitidb kloopzmq searchmq' > /etc/hosts
echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts

# disable ruby doc, this would speed up the install while a bit
echo 'gem: --no-document' >> ~/.gemrc

# java
echo "OO installing open jdk 1.8"
yum -y install java-1.8.0-openjdk-devel

# misc
yum -y install git wget vim-common ntp perl-Digest-SHA
systemctl enable ntpd
systemctl start ntpd

# postgres
echo "OO install postgres 9.2"
yum -y install http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-8.noarch.rpm
yum -y install postgresql92-server postgresql92-contrib
yum -y install postgresql-devel

echo "OO init postgres database"
rm -fr /var/lib/pgsql/9.2/data/*
/usr/pgsql-9.2/bin/postgresql92-setup initdb

echo "OO changing postgres config to allow local connections"

cp "$VAGRANT_MNT/pgsql/9.2/pg_hba.conf" /var/lib/pgsql/9.2/data
chown postgres:postgres /var/lib/pgsql/9.2/data/pg_hba.conf

echo "OO starting postgres db"
systemctl enable postgresql-9.2
systemctl start postgresql-9.2
echo "OO done with postgres"

apache_mirror="http://www.us.apache.org/dist"
apache_archive="http://archive.apache.org/dist"

amq_version="5.10.2"
echo "OO install activemq $amq_version"
cd /opt
wget -nv $apache_mirror/activemq/$amq_version/apache-activemq-$amq_version-bin.tar.gz
if [ ! -e "/opt/apache-activemq-$amq_version-bin.tar.gz" ]; then
  wget -nv $apache_archive/activemq/$amq_version/apache-activemq-$amq_version-bin.tar.gz
fi

if [ ! -e "/opt/apache-activemq-$amq_version-bin.tar.gz" ]; then
  echo "Can not get Activemq distribution! "
  exit 1
fi

tar -xzvf apache-activemq-$amq_version-bin.tar.gz
ln -sf ./apache-activemq-$amq_version activemq
cp "$VAGRANT_MNT/amq/5.10/init.d/activemq" /etc/init.d
cp "$VAGRANT_MNT/amq/credentials.properties" /opt/activemq/conf/
chown root:root /etc/init.d/activemq
chmod +x /etc/init.d/activemq
chkconfig --add activemq
chkconfig activemq on
service activemq start
echo "OO done with activemq"

c_version="2.2.5"
echo "OO install cassandra $c_version"
cd /opt
wget -nv $apache_mirror/cassandra/$c_version/apache-cassandra-$c_version-bin.tar.gz
if [ ! -e "/opt/apache-cassandra-$c_version-bin.tar.gz" ]; then
  wget -nv $apache_archive/cassandra/$c_version/apache-cassandra-$c_version-bin.tar.gz
fi
if [ ! -e "/opt/apache-cassandra-$c_version-bin.tar.gz" ]; then
  echo "Can not get Cassandra distribution! "
  exit 1
fi
tar -xzvf apache-cassandra-$c_version-bin.tar.gz
ln -sf apache-cassandra-$c_version cassandra
mkdir -p /opt/cassandra/log
cp "$VAGRANT_MNT/cassandra/2.1/init.d/cassandra" /etc/init.d

chown root:root /etc/init.d/cassandra
chmod +x /etc/init.d/cassandra
chkconfig --add cassandra
chkconfig cassandra on
service cassandra start
echo "OO done with cassandra"

t_version="7.0.67"
echo "OO install tomcat $t_version"
cd /opt
wget -nv $apache_mirror/tomcat/tomcat-7/v$t_version/bin/apache-tomcat-$t_version.tar.gz
if [ ! -e "/opt/apache-tomcat-$t_version.tar.gz" ]; then
  wget -nv $apache_archive/tomcat/tomcat-7/v$t_version/bin/apache-tomcat-$t_version.tar.gz
fi
if [ ! -e "/opt/apache-tomcat-$t_version.tar.gz" ]; then
  echo "Can not get Tomcat distribution! "
  exit 1
fi
tar -xzvf apache-tomcat-$t_version.tar.gz
mv apache-tomcat-$t_version /usr/local/tomcat7
useradd -M -d /usr/local/tomcat7 tomcat7
chown -R tomcat7 /usr/local/tomcat7
cp "$VAGRANT_MNT/tomcat/7.0/init.d/tomcat7" /etc/init.d
chown root:root /etc/init.d/tomcat7
chmod 755 /etc/init.d/tomcat7
chkconfig --add tomcat7
chkconfig tomcat7 on
service tomcat7 start
echo "OO done with tomcat $t_version"

m_version="3.3.3"
echo "OO install maven $m_version"
cd /opt
wget -nv $apache_mirror/maven/maven-3/$m_version/binaries/apache-maven-$m_version-bin.tar.gz
if [ ! -e "/opt/apache-maven-$m_version-bin.tar.gz" ]; then
  wget -nv $apache_archive/maven/maven-3/$m_version/binaries/apache-maven-$m_version-bin.tar.gz
fi
if [ ! -e "/opt/apache-maven-$m_version-bin.tar.gz" ]; then
  echo "Can not get Maven distribution! "
  exit 1
fi
tar -xzvf apache-maven-$m_version-bin.tar.gz -C /usr/local
cd /usr/local
ln -sf apache-maven-$m_version maven
touch /etc/profile.d/maven.sh
echo 'export M2_HOME=/usr/local/maven' >> /etc/profile.d/maven.sh
echo 'export PATH=${M2_HOME}/bin:${PATH}' >> /etc/profile.d/maven.sh
echo "OO done with maven"

echo "OO generate des file"
mkdir -p /usr/local/oneops/certs
cd /usr/local/oneops/certs
if [ ! -e oo.key ]; then
dd if=/dev/urandom count=24 bs=1 | xxd -ps > oo.key
##truncate newline at the end
truncate -s -1 oo.key
fi
echo "OO Done with des file"


# misc packages
yum install -y gcc gcc-c++ ruby-devel zlib-devel nc bind-utils

# gem build deps
yum -y install libxml2-devel libxslt-devel graphviz

#
# ruby
#

yum -y install rubygems ruby-devel
gem update --system 2.6.1
gem install json -v 1.8.3
gem install bundler
gem install rake
gem install net-ssh -v 2.9.1
gem install mixlib-log -v '1.6.0'
echo "export PATH=$PATH:/usr/local/bin" > /etc/profile.d/gem_bin.sh

cp "$VAGRANT_MNT/display/init.d/display" /etc/init.d
chkconfig --add display
chkconfig display on


#
# elasticsearch
#

echo "OO install elasticsearch"
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch

echo "[elasticsearch-1.7]
name=Elasticsearch repository for 1.7.x packages
baseurl=http://packages.elastic.co/elasticsearch/1.7/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1" > /etc/yum.repos.d/elasticsearch.repo
yum -y install elasticsearch

export ES_HEAP_SIZE=512m
echo "export ES_HEAP_SIZE=512m" > /etc/profile.d/es.sh
sed -i -- 's/\#cluster\.name\: elasticsearch/cluster\.name\: oneops/g' /etc/elasticsearch/elasticsearch.yml

systemctl enable elasticsearch
systemctl start elasticsearch

cp "$VAGRANT_MNT/search-consumer/init.d/search-consumer" /etc/init.d
chkconfig --add search-consumer
chkconfig search-consumer on


cp "$VAGRANT_MNT/search-consumer/cms_template.json" /tmp
cp "$VAGRANT_MNT/search-consumer/event_template.json" /tmp

curl http://localhost:9200
while [ $? != 0 ]; do
        sleep 1
        curl http://localhost:9200
done

curl -d @/tmp/cms_template.json -X PUT http://localhost:9200/_template/cms_template
curl -d @/tmp/event_template.json -X PUT http://localhost:9200/_template/event_template

echo "OO done with elasticsearch"


#Setup certs for collector and forwarder
echo '127.0.0.1 vagrant.oo.com' >> /etc/hosts

mkdir -p /etc/pki/tls/logstash/certs
mkdir -p /etc/pki/tls/logstash/private

cd /etc/pki/tls/logstash
openssl req -x509 -batch -nodes -days 3650 -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt -subj '/CN=*.oo.com/'

mkdir -p /etc/logstash/conf.d
cp "$VAGRANT_MNT/logstash/logstash.conf" /etc/logstash/conf.d/logstash.conf

#
# logstash
#

echo "OO install logstash"

echo "[logstash-1.5]
name=Logstash repository for 1.5.x packages
baseurl=http://packages.elastic.co/logstash/1.5/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1" > /etc/yum.repos.d/logstash.repo

yum -y install logstash

chkconfig --add logstash
chkconfig logstash on
service logstash start

