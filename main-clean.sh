#!/bin/bash
export EC2_CERT=/root/.ec2/cert.pem
export EC2_HOME=/home/ec2
export EC2_PRIVATE_KEY=/root/.ec2/pk.pem
export JAVA_HOME=/usr/java/default

/home/ec2/bin/ec2-describe-snapshots --region eu-west-1 |grep "CreateImage" |awk '{ system("/home/ec2/bin/ec2-delete-snapshot --region eu-west-1 "$2)}'
