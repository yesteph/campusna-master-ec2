# Customize an EC2 instance with user-data and create an AMI

In this exercise, you will start an EC2 instance and configure it with `user-data` to install an Apache server and format and mount an EBS volume.

This EBS volume will contains the web server content - directory `/var/www/html`.

Then, you will connect the instance to change the web content.
At this stage, you can create an AMI to be able to persist the current configuration and launch several other instances.

Finally, you create a new instance with the created AMI.

## Pre-requisites

Each participant must have a dedicated AWS account and access to the WebConsole with Administrator Access.

Inside an account, the Terraform configuration in `./terraform` must have been applied to create a VPC, subnets and route tables in region `eu-west-3`

## Create an EC2 instance with a WebServer

Connect to the [AWS WebConsole](https://aws.amazon.com/console/).
Ensure you are on the Paris region. If not, select it. 

[screenshot](./res/regions.png)

Then go to the EC2 service and click on the `Instances` and `Launch Instances` buttons:
* Use the `Amazon Linux 2 AMI`. It is generally the first one.
* Keep the default instance type.
* On the `Configure Instance Details`, select `master-ec2-vpc` and a `*-public` subnet.
* On the `Advanced Details/ User data` section, select `ssm` for the IAM role.
* Scroll down the web page to see the `Advanced Details/ User data` section and copy this content
```sh
#!/bin/bash
yum update –y
sudo mkfs -t ext4 /dev/sdb
sudo mkdir -p /var/www/html
echo "/dev/sdb       /var/www/html/   ext4    defaults,nofail        0       0" >> /etc/fstab
sudo mount -a
yum install httpd -y
# // Disactive SELinux
setenforce 0
systemctl start httpd
systemctl enable httpd
```
* Add Storage: in addtition of the root volume, create a new EBS volume
  * attached to /dev/sdb
  * size of 1 GB
* Add Tags
  * add a key/value: 'Name'/'builder'
* Configure Security groups
  * Select an existing security group
  * Choose `allow_http_ssh` for the securty group


Click on `Review and launch` then `Launch`. You will get a message asking to select a key pair, choose `student` if it is not done yet.

Then launch the instance.

Click on `View instances`. You should see the created EC2 instance.

## Test installation of the web server

Once the instance is in `Running` state, copy the public IP address and open it in your web browser.
Because we have used user-data to install a web server, you should see a web page.

## Connect to the instance

We will connect to the server to change the web content.
In the AWS Console, click on `Connect` then choose `Session Manager`.

## Access the metadata server

The metadata server answers on the address http://169.254.169.254. This is the case for all EC2 instances.

Run this command to see the user-data you passed at creation time:
```sh
curl http://169.254.169.254/latest/user-data/
```

## Change the web content

Edit the `/var/www/html/index.html`page to put this content:
```sh
sudo su
cat <<EOT > /var/www/html/index.html
<!DOCTYPE html>
<html>
<body>

<h1>My Custom WebPage</h1>
<p>My custom paragraph.</p>

</body>
</html>
EOT
```

Refresh the page in you browser to see the new content.

## Create an AMI

On the AWS Console, select the instance and click on `Actions / Template and Images / Create Image`

Enter a name: `web-server`
Look at the volume section. You should see one volume for the Operating System and another of 1 GB which contains the web content.

Click on `Create image`.

## Create new instance with the new AMI.

Go to EC2 / AMIs.

Once the AMI is in `available` state, you can create a new server with the update web content.

Select the AMI and click `Actions / Launch`:
* Keep the default instance type
* On the `Configure Instance Details`, select `master-ec2-vpc` and a **public** subnet
* On the `Advanced Details/ User data` section, select `ssm` for the IAM role
* Add Tags
  * add a key/value: 'Name'/'test'
* Configure Security groups
  * Select an existing security group
  * Choose `allow_http_ssh` for the securty group


Click on `Review and launch` then `Launch`. You will get a message asking to select a key pair, choose `student`if it is not done yet.

Then launch the instance.

Click on `View instances`. You should see the created EC2 instance.

When it is running, open its public IP in your web browser to see the web content you set on the first instance.

