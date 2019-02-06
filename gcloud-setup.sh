#/bin/bash

DO_FIREWALL=no
DO_INSTANCE=no
DO_CRD=yes

GC_PROJECT=${GOOGLE_CLOUD_PROJECT:-"$(gcloud config get-value core/project --quiet)"}
GC_ZONE="$(gcloud config get-value compute/zone --quiet)"
GC_TYPE_DEFAULT=ubuntu

GC_PREFIX="crd-"

tmp=""
read -p "GCE Project ($GC_PROJECT): " tmp
GC_PROJECT=${tmp:-$GC_PROJECT}

tmp=""
read -p "GCE Zone ($GC_ZONE): " tmp
GC_ZONE=${tmp:-$GC_ZONE}

tmp=""
read -p "Setup GCE Firewall Rule ($DO_FIREWALL): " tmp
DO_FIREWALL=${tmp:-$DO_FIREWALL}
DO_FIREWALL=`echo $DO_FIREWALL | sed -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/'`
case "$DO_FIREWALL" in
   y)
     DO_FIREWALL="yes"
     ;;
   yes)
     DO_FIREWALL="yes"
     ;;
   *)
     DO_FIREWALL="no"
     ;;
esac    

tmp=""
read -p "Setup GCE Instance for CRD ($DO_INSTANCE): " tmp
DO_INSTANCE=${tmp:-$DO_INSTANCE}
DO_INSTANCE=`echo $DO_INSTANCE | sed -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/'`
case "$DO_INSTANCE" in
   y)
     DO_INSTANCE="yes"
     ;;
   yes)
     DO_INSTANCE="yes"
     ;;
   *)
     DO_INSTANCE="no"
     ;;
esac    

#
# Set a unique name containing only a-z, 0-9 and '-'
echo "Using Only Letters..."
CRD_USER=""
while [ "$CRD_USER" = "" ]; do
  read -p "  Enter your first and last name: " CRD_USER
  CRD_USER=`echo $CRD_USER  | sed -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ /abcdefghijklmnopqrstuvwxyz-/' | sed -e 's/[^a-z\-]//g' | sed -e 's/--*/-/g' | sed -e 's/-*$//' | sed -e 's/^-*//'` 
done

CRD_GCE=$GC_PREFIX$CRD_USER
echo 
echo
echo "Instance: $CRD_GCE"
echo "Username: $CRD_USER"
echo "Project:  $GC_PROJECT"
echo "Zone:     $GC_ZONE"
echo "Setup FW: $DO_FIREWALL"
echo "Setup VM: $DO_INSTANCE"
echo 
echo


GCSSH="gcloud compute ssh --project $GC_PROJECT --zone $GC_ZONE $CRD_USER@$CRD_GCE"

if [ "$DO_FIREWALL" = "yes" ]; then
  echo "Setting up VPC Firewall rule for CRD..."
  gcloud compute firewall-rules create \
    desktop-allow-xmpp \
    --project $GC_PROJECT \
    --target-tags chrome-desktop \
    --allow tcp:5222 \
    --network default \
    --source-ranges "0.0.0.0/0" \
    --priority=64000
fi

if [ "$DO_INSTANCE" = "yes" ]; then


tmp=""
read -p "Setup GCE Instance as ($GC_TYPE_DEFAULT): " tmp
GC_TYPE=${tmp:-$GC_TYPE_DEFAULT}
GC_TYPE=`echo $GC_TYPE | sed -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/'`
case "$GC_TYPE" in
   y)
     GC_TYPE=$GC_TYPE_DEFAULT
     ;;
   yes)
     GC_TYPE=$GC_TYPE_DEFAULT
     ;;
   *)
     ;;
esac    

case "$GC_TYPE" in
   debian)
     GC_IMAGE_PROJECT=debian-cloud
     GC_IMAGE_FAMILY=debian-9
     GC_DISK_SIZE=120GB
     GC_STARTUP_SCRIPT_URL=gs://$GC_PROJECT-crd-startup-script/crd-startup-debian.sh
     ;;
   ubuntu)
     GC_IMAGE_PROJECT=ubuntu-os-cloud
     GC_IMAGE_FAMILY=ubuntu-1810
     GC_DISK_SIZE=120GB
     GC_STARTUP_SCRIPT_URL=gs://$GC_PROJECT-crd-startup-script/crd-startup-ubuntu.sh
     ;;
   *)
     echo "Unsupported instance type..."
     exit 1
     ;;
esac

gsutil ls $GC_STARTUP_SCRIPT_URL 2>1 >/dev/null
retval=$?
if [ "$retval" = "1" ]; then
  echo "$GC_STATUP_SCRIPT_URL does not exist... run update-bucket.sh"
  exit 1
fi

tmp=""
read -p "Do you want to Setup Chrome Remote Desktop on the GCE Instance ($DO_CRD): " tmp
DO_CRD=${tmp:-$DO_CRD}
DO_CRD=`echo $DO_CRD | sed -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/'`
case "$DO_CRD" in
   y)
     DO_CRD="yes"
     ;;
   yes)
     DO_CRD="yes"
     ;;
   *)
     DO_CRD="no"
     ;;
esac

#
# Assumes that you have placed ssh keys at .ssh/google_compute_engine.pub
#

if [ ! -e ~/.ssh/google_compute_engine.pub ]; then
  echo "You have not set up your google_compute_engine ssh keys as of yet.."

    echo "Generating them now..."
    ssh-keygen -b 521 -t ecdsa -f ~/.ssh/google_compute_engine -N "" -C $CRD_USER
    chmod 400 ~/.ssh/google_compute_engine ~/.ssh/google_compute_engine.pub

  echo "This SSH keypair will be copied to your GCE instance..." 
fi

  echo "Setting up GCE $GC_TYPE instance for CRD using:"
  echo "  image-project: $GC_IMAGE_PROJECT"
  echo "  image-family:  $GC_IMAGE_FAMILY"
  echo "  boot-disk-size: $GC_DISK_SIZE"
  echo -n "..."
  gcloud compute instances create \
    --boot-disk-size $GC_DISK_SIZE \
    --boot-disk-type pd-ssd \
    --boot-disk-auto-delete \
    --image-project $GC_IMAGE_PROJECT \
    --image-family $GC_IMAGE_FAMILY \
    --machine-type n1-standard-2 \
    --labels usage=dev,owner=$CRD_USER \
    --zone $GC_ZONE \
    --tags chrome-desktop,default \
    --project $GC_PROJECT \
    --description "CRD Instance for $CRD_USER" \
    --metadata block-project-ssh-keys=TRUE,ssh-keys="$CRD_USER:`cat ~/.ssh/google_compute_engine.pub`",startup-script-url=$GC_STARTUP_SCRIPT_URL \
    --scopes https://www.googleapis.com/auth/cloud-platform \
    $CRD_GCE
    #--no-service-account \
    #--no-scopes \
    #--scopes storage-ro \

  echo "done"
  echo -n "Waiting for GCE instance to start..."
  sleep 7
  retVal=""
  while [ "$retVal" != "0" ]; do
    sleep 3
    $GCSSH --command "echo" > /dev/null 2>&1
    retVal=$?
    echo -n "."
  done
  echo "running"
  echo -n "Waiting for GCE startup script to finish..."
  sleep 7
  retVal=""
  while [ "$retVal" != "0" ]; do
    sleep 3
    $GCSSH --command "[ -e /startup-work/done ]" > /dev/null 2>&1
    retVal=$?
    echo -n "."
  done
  echo "done"
  DONE_STRING=`$GCSSH --command "cat /startup-work/done" 2>/dev/null`
  SCRIPT_VERSION=`echo $DONE_STRING | cut -f1 -d:`
  MY_NAME=`echo $DONE_STRING | cut -f2 -d:`
  MY_IP=`echo $DONE_STRING | cut -f3 -d:`
  echo
  echo "Startup Script Version: "$SCRIPT_VERSION
  echo "GCE Instance Node Name: "$MY_NAME
  echo "GCE Instance Extern IP: "$MY_IP
  echo
  echo "Setup up User Account..."
  $GCSSH --command "sudo usermod -a -G chrome-remote-desktop \$USER"

  #Make your life easier and set passowrd for the user on the remote machine
  #echo 
  #echo "Enter new password for $CRD_USER on GCE VM"
  #$GCSSH --command "sudo passwd \$USER"

  
  echo
  
  if [ "$DO_CRD" = "yes" ]; then

    echo "Configuring CRD..."
    # read -p "Enter Password to set for $CRD_USER on VM: " -s CRD_PASS
    # echo
    CRD_PIN=""
    while [ "$CRD_PIN" = "" ]; do
      read -p "Enter a six digit PIN to set for CRD server: " tmp1
      tmp2=`echo $tmp1  | sed -e 's/[^0-9]//g'` 
      if [ "$tmp1" == "$tmp2" ]; then
        if [ "${#tmp1}" = "6" ]; then
         CRD_PIN=$tmp1
        fi
      fi
    done
    echo  "PIN:  $CRD_PIN" 
    #Via a browser goto https://remotedesktop.google.com/headless 
    #to get something like the below 
    #    /opt/google/chrome-remote-desktop/start-host --code="xxxxxxxxx" --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=

    echo 
    echo "1) Goto ..."
    echo 
    echo "https://remotedesktop.google.com/headless" 
    echo
    echo "   ... in a web browser"
    echo 
    echo "2) Click 'SET UP COMPUTER VIA COMMAND LINE'"
    echo
    crdtmp=""
    while [ "$crdtmp" = "" ]; do
      read -p "3) Copy the resulting AUTH command and PASTE IT HERE >>>>>>>  " crdtmp
    done
    
    crdAuth="$crdtmp$CRD_GCE --pin=$CRD_PIN"
    
    crdAuthEsc=`echo "$crdAuth" | sed -e 's/\"/\\\"/g'`
    crdAuthEscCmd="bash -l -c "'"'$crdAuthEsc'"'
    echo
   
    #echo "   "$crdAuth
    #echo "   "$crdAuthEsc
    #echo "   "$crdAuthEscCmd
    
    $GCSSH --command="$crdAuthEscCmd"
    $GCSSH --command="/opt/google/chrome-remote-desktop/chrome-remote-desktop -k"
    $GCSSH --command="/opt/google/chrome-remote-desktop/chrome-remote-desktop --start -s 3440x1440"
  fi
fi
  
echo "To access your new GCE instance use:"
echo 
echo "   $GCSSH"
echo 
echo "To restart your CRD host after your GCE instance is restarted:"
echo 
echo "   $GCSSH --command=\"/opt/google/chrome-remote-desktop/chrome-remote-desktop --start -s 3440x1440\""
echo
echo "To access your CRD host desktop:"
echo
echo "   https://remotedesktop.google.com/access"
echo
exit 0
#/bin/bash

GC_PROJECT=$GOOGLE_CLOUD_PROJECT

gsutil mb gs://$GC_PROJECT-crd-startup-script 
gsutil cp crd-startup*.sh gs://$GC_PROJECT-crd-startup-script/ 
systemctl set-default multi-user.target
sudo systemctl stop gdm.service
systemctl disable gdm.service
systemctl disable chrome-remote-desktop
