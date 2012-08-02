#!/bin/bash
echo "
################################
## Super AMazon Backup System ##
##          SAMBS             ##
################################
"
set -x
export EC2_CERT=/root/.ec2/cert.pem
export EC2_HOME=/home/ec2
export EC2_PRIVATE_KEY=/root/.ec2/pk.pem
export JAVA_HOME=/usr/java/default

rootdir=/root/SAMBS
volconf=$rootdir/conf/volumes.conf
imgconf=$rootdir/conf/instances.conf
datadir=$rootdir/data

ec2bindir=/home/ec2/bin

ec2crsn=$ec2bindir/ec2-create-snapshot
ec2crim=$ec2bindir/ec2-create-image
ec2dlsn=$ec2bindir/ec2-delete-snapshot
ec2dlim=$ec2bindir/ec2-deregister


c_hourly=7
c_daily=12
c_weekly=5
c_monthly=12

function get_snapid {
        return cat $1 | awk '{print $2}'
}

function get_last {
     echo $(head -n1 $1)
}

function get_first {
     echo $(tail -n1 $1)
}

function get_count {
     echo $(wc $datadir/$2/$1.list |awk '{print $1}')
}

function get_date {
     echo $(date +%d.%m.%y_%H:%M)
}

function parseconfig {
     cat $1 | while read line
     do
      echo $line
     done
}

function parser {
     case $1 in
          id)
               echo $2
               ;;
          name)
               echo $3               ;;
          *)
               echo "Error"
     esac
}

function ifmore {
     case $1 in
          hourly)
               echo $c_hourly
               ;;
          daily)
               echo $c_daily
               ;;
          weekly)
               echo $c_weekly
               ;;
          monthly)
               echo $c_monthly
               ;;
          *)
               echo "Error in case"
     esac
}

function create_snapshot {
     tmp=$($ec2crsn $1 -d SAMBS_$3_$1_$2_$(get_date) --region eu-west-1)
     #tmp=$(echo "SNAPSHOT        snap-aea11fc6   vol-e449688d    pending 2011-11-08T11:03:30+0000                785370008234    100     video.condenast.ru_backup")
     echo $tmp | awk '{print $2}'
}

function delete_snapshot {
     tmp=$($ec2dlsn $(get_last $datadir/$2/$1.list) --region eu-west-1)
     sed -i '1,1d' $datadir/$2/$1.list
}

function create_image {
     tmp=$($ec2crim $1 -n $3_$1_$2_$(get_date) -d SAMBS_$3_$1_$2_$(get_date) --no-reboot --region eu-west-1)
     #tmp=$(echo "IMAGE   ami-d1eed2a5")
        echo $tmp | awk '{print $2}'
}

function delete_image {
     tmp=$($ec2dlim $(get_last $datadir/$2/$1.list) --region eu-west-1)
        sed -i '1,1d' $datadir/$2/$1.list
}

function exec_snapshots {
     #for i in $(parseconfig $volconf ); do
        cat $volconf | while read i
     do
         echo $(create_snapshot $(parser id $i) $1 $(parser name $i)) >> $datadir/$1/$(parser id $i).list
            [ "$(get_count $(parser id $i) $1)" -gt "$(ifmore $1)" ] && delete_snapshot $(parser id $i) $1
        done
}

function exec_images {
     #for i in $(parseconfig $imgconf ); do
        cat $imgconf | while read i
        do
         echo $(create_image $(parser id $i) $1 $(parser name $i)) >> $datadir/$1/$(parser id $i).list
            [ "$(get_count $(parser id $i) $1)" -gt "$(ifmore $1)" ] && delete_image $(parser id $i) $1
        done
}
#main functions

function hourly {
     exec_snapshots hourly
}
function daily {
     exec_snapshots daily
     exec_images daily
}
function weekly {
     exec_snapshots weekly
        exec_images weekly
}
function monthly {
     exec_snapshots monthly
        exec_images monthly
}

function main {
     case $1 in
          hourly)
               hourly
               ;;
          daily)
               daily
               ;;
          weekly)
               weekly
               ;;
          monthly)
               monthly
               ;;
          help)
               echo "help"
               ;;
          *)
          echo "Usage: hourly | daily | weekly | monthly "
     esac
}
main $1

