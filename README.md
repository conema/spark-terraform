# Hadoop/Spark with Terraform on AWS

This project create an Hadoop and Spark cluster on Amazon AWS with Terraform

1. [Variables](#Variables)
2. [Software version](#Software-version)
3. [Project Structure](#Project-Structure)
4. [How to](#How-to)
5. [See also](#See-also)

## Variables

| Name           | Description                                | Default               |
|----------------|--------------------------------------------|-----------------------|
| region         | AWS region                                 | us-east-1             |
| access_key     | AWS access key                             |                       |
| secret_key     | AWS secret key                             |                       |
| token          | AWS token                                  | null                  |
| instance_type  | AWS instance type                          | m5.xlarge             |
| ami_image      | AWS AMI image                              | ami-0885b1f6bd170450c |
| key_name       | Name of the key pair used between nodes    | localkey              |
| key_path       | Path of the key pair used between nodes    | .                     |
| aws_key_name   | AWS key pair used to connect to nodes      | amzkey                |
| amz_key_path   | AWS key pair path used to connect to nodes | amzkey.pem            |
| namenode_count | Namenode count                             | 1                     |
| datanode_count | Datanode count                             | 3                     |
| ips            | Default private ips used for nodes         | See variables.tf      |
| hostnames      | Default private hostnames used for nodes   | See variables.tf      |


## Software version
* Default AMI image: ami-0885b1f6bd170450c (Ubuntu 20.04, amd64, hvm-ssd)
* Spark: 3.0.1
* Hadoop: 2.7.7
* Python: last available (currently 3.8)
* Java: openjdk 8u275 jdk

## Project Structure

* app/: folder where you can put your application, it will copied to the namenode
* install-all.sh: script which is executed in every node, it install hadoop/spark and do all the configuration for you
* main.tf: definition of the resources 
* output.tf: terraform output declaration
* variables.tf: terraform variable declaration


## How to

0. Download and install Terraform
1. Download the project and unzip it
2. Open the terraform project folder "spark-terraform-master/"
3. Create a file named "terraform.tfvars" and paste this:
```
access_key="<YOUR AWS ACCESS KEY>"
secret_key="<YOUR AWS SECRET KEY>"
token="<YOUR AWS TOKEN>"
```
**Note:** without setting the other variables (you can find it on variables.tf), terraform will create a cluster on region "us-east-1", with 1 namenode, 3 datanode and with an instance type of m5.xlarge.

3. Put your application files into the "app" terraform project folder 
4. Open a terminal and generate a new ssh-key
```
ssh-keygen -f <PATH_TO_SPARK_TERRAFORM>/spark-terraform-master/localkey
```
Where `<PATH_TO_SPARK_TERRAFORM>` is the path to the /spark-terraform-master/ folder (e.g. /home/user/)

5. Login to AWS and create a key pairs named **amzkey** in **PEM** file format. Follow the guide on [AWS DOCS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair). Download the key and put it in the spark-terraform-master/ folder.

6. Open a terminal and go to the spark-terraform-master/ folder, execute the command
 ```
 terraform init
 terraform apply
 ```
 After a while (wait!) it should print some public DNS in a green color, these are the public dns of your instances.

7. Connect via ssh to all your instances via
 ```
ssh -i <PATH_TO_SPARK_TERRAFORM>/spark-terraform-master/amzkey.pem ubuntu@<PUBLIC DNS>
 ```

8. Execute on the master (one by one):
 ```
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh
$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver' > /home/ubuntu/hadoop-start-master.sh
$SPARK_HOME/sbin/start-master.sh
$SPARK_HOME/sbin/start-slaves.sh spark://s01:7077
```

9. You are ready to execute your app! Execute this command on the master
```
/opt/spark-3.0.1-bin-hadoop2.7/bin/spark-submit --master spark://s01:7077  --executor-cores 2 --executor-memory 14g yourfile.py
```

10. Remember to do `terraform destroy` to delete your EC2 instances

**Note:** The steps from 0 to 5 (included) are needed only on the first execution ever


## See also
 * [TransE PySpark](https://github.com/conema/TransE-pyspark): an application using this project
 * [hadoop-spark-cluster-deployment](https://github.com/kostistsaprailis/hadoop-spark-cluster-deployment): the starting point of this project
