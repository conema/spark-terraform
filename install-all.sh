!#/bin/bash

# wait that the boot finish, otherwise apt-get could fail
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# install some packages
sudo apt-get -y update
#sudo apt-get -y dist-upgrade
sudo apt-get -y install git
sudo apt-get -y install python3
sudo apt-get -y install python3-pip
pip3 install findspark
pip3 install numpy
sudo apt-get -y install openjdk-8-jdk

# master and slaves ip (you can add more if needed)
echo '
172.31.0.101 s01
172.31.0.102 s02
172.31.0.103 s03
172.31.0.104 s04
172.31.0.105 s05
172.31.0.106 s06' | sudo tee --append /etc/hosts > /dev/null

sudo chmod 700 /home/ubuntu/.ssh
sudo chmod 600 /home/ubuntu/.ssh/id_rsa

echo '
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin
export PYSPARK_PYTHON=python3' | sudo tee --append /home/ubuntu/.bashrc > /dev/null

# install hadoop 2.7.7
cd /opt/
sudo wget https://archive.apache.org/dist/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz > /dev/null
sudo tar zxvf hadoop-2.7.7.tar.gz > /dev/null

# hadoop configuration files
echo '
export HADOOP_HOME=/opt/hadoop-2.7.7
export PATH=$PATH:$HADOOP_HOME/bin
export HADOOP_CONF_DIR=/opt/hadoop-2.7.7/etc/hadoop' | sudo tee --append /home/ubuntu/.bashrc > /dev/null

echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://s01:9000</value>
  </property>
</configuration>' | sudo tee /opt/hadoop-2.7.7/etc/hadoop/core-site.xml > /dev/null

echo '<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>s01</value>
  </property>
</configuration>' | sudo tee /opt/hadoop-2.7.7/etc/hadoop/yarn-site.xml > /dev/null

sudo cp /opt/hadoop-2.7.7/etc/hadoop/mapred-site.xml.template /opt/hadoop-2.7.7/etc/hadoop/mapred-site.xml

echo '<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>mapreduce.jobtracker.address</name>
    <value>s01:54311</value>
  </property>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>' | sudo tee /opt/hadoop-2.7.7/etc/hadoop/mapred-site.xml > /dev/null

echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>2</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///opt/hadoop-2.7.7/hadoop_data/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///opt/hadoop-2.7.7/hadoop_data/hdfs/datanode</value>
  </property>
</configuration>' | sudo tee /opt/hadoop-2.7.7/etc/hadoop/hdfs-site.xml > /dev/null

echo '
s01' | sudo tee --append /opt/hadoop-2.7.7/etc/hadoop/masters > /dev/null

echo '
s02
s03
s04
s05
s06' | sudo tee /opt/hadoop-2.7.7/etc/hadoop/slaves > /dev/null

sudo sed -i -e 's/export\ JAVA_HOME=\${JAVA_HOME}/export\ JAVA_HOME=\/usr\/lib\/jvm\/java-8-openjdk-amd64/g' /opt/hadoop-2.7.7/etc/hadoop/hadoop-env.sh

sudo mkdir -p /opt/hadoop-2.7.7/hadoop_data/hdfs/namenode
sudo mkdir -p /opt/hadoop-2.7.7/hadoop_data/hdfs/datanode

sudo chown -R ubuntu /opt/hadoop-2.7.7


# spark installation
cd /opt/
sudo wget https://downloads.apache.org/spark/spark-3.0.1/spark-3.0.1-bin-hadoop2.7.tgz > /dev/null
sudo tar -xvzf spark-3.0.1-bin-hadoop2.7.tgz > /dev/null

echo '
export SPARK_HOME=/opt/spark-3.0.1-bin-hadoop2.7
export PATH=$PATH:$SPARK_HOME/bin' | sudo tee --append /home/ubuntu/.bashrc > /dev/null

sudo chown -R ubuntu /opt/spark-3.0.1-bin-hadoop2.7

cd spark-3.0.1-bin-hadoop2.7

cp conf/spark-env.sh.template conf/spark-env.sh  


# spark configuration files
echo '
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export SPARK_MASTER_HOST=s01
export HADOOP_CONF_DIR=/opt/hadoop-2.7.7/etc/hadoop
export HADOOP_HOME=/opt/hadoop-2.7.7' | sudo tee --append conf/spark-env.sh > /dev/null

echo '
s02
s03
s04
s05
s06' | sudo tee --append conf/slaves > /dev/null

cp conf/spark-defaults.conf.template conf/spark-defaults.conf


echo -e '$HADOOP_HOME/sbin/start-dfs.sh && $HADOOP_HOME/sbin/start-yarn.sh && $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver' > /home/ubuntu/hadoop-start-master.sh

echo '$SPARK_HOME/sbin/start-master.sh' > /home/ubuntu/spark-start-master.sh

echo '$SPARK_HOME/sbin/start-slave.sh spark://s01:7077' > /home/ubuntu/spark-start-slave.sh