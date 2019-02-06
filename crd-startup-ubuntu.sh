#/bin/bash

SCRIPT_VERSION="1"

WDIR=/startup-work

#
# Three ways to grab the external IP!
#
#gcloud compute instances describe `uname -n` --format='get(networkInterfaces.accessConfigs.natIP)'
#wget -q -O - --header="Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip"
#curl "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google"

MY_NAME=`uname -n`
MY_IP=`curl "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google"`

if [ ! -e $WDIR/done ]; then

  # Run Once at instance setup time!
  
  mkdir $WDIR
  cd $WDIR 

  echo "Installing Gnome..."
  apt-get update 
  apt-get update 
  apt-get install debconf-utils
  debconf-set-selections <<-EOF00
	keyboard-configuration  keyboard-configuration/modelcode        string  pc105
	keyboard-configuration  keyboard-configuration/store_defaults_in_debconf_db     boolean true
	keyboard-configuration  keyboard-configuration/unsupported_config_options       boolean true
	keyboard-configuration  keyboard-configuration/variantcode      string
	keyboard-configuration  keyboard-configuration/ctrl_alt_bksp    boolean false
	keyboard-configuration  keyboard-configuration/switch   select  No temporary switch
	keyboard-configuration  keyboard-configuration/unsupported_layout       boolean true
	keyboard-configuration  keyboard-configuration/xkb-keymap       select  us
	keyboard-configuration  keyboard-configuration/unsupported_options      boolean true
	keyboard-configuration  keyboard-configuration/compose  select  No compose key
	keyboard-configuration  keyboard-configuration/toggle   select  No toggling
	keyboard-configuration  keyboard-configuration/model    select  Generic 105-key (Intl) PC
	keyboard-configuration  keyboard-configuration/optionscode      string
	keyboard-configuration  keyboard-configuration/layout   select
	keyboard-configuration  keyboard-configuration/layoutcode       string  us
	keyboard-configuration  keyboard-configuration/variant  select  English (US)
	keyboard-configuration  keyboard-configuration/unsupported_config_layout        boolean true
	keyboard-configuration  keyboard-configuration/altgr    select  The default for the keyboard layout
EOF00

  apt-get install -y dbus
  apt-get install -y xvfb
  apt-get install -y gnome-core
#  apt-get install -y ubuntu-gnome-desktop
#  apt-get remove  -y network-manager-config-connectivity-ubuntu
#  apt-get install lightdm lightdm-gtk-greeter light-locker ligh#t-locker-settings
  apt-get install -y git
  apt-get install -y docker.io
  snap install kubectl --classic
  apt-get install -y -f
  cat > /etc/polkit-1/localauthority/50-local.d/allow-colord.pkla <<-EOF01
	[Allow colord for all users]
	Identity=unix-user:*
	Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile 
	ResultAny=yes
	ResualtInactive=auth_admin
	ResultActive=yes
EOF01

  echo
  echo "Install CRD..."
  wget "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  wget "https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"
  dpkg --install google-chrome-stable_current_amd64.deb
  apt-get -y -f install
  dpkg --install chrome-remote-desktop_current_amd64.deb
  apt-get -y -f install
 
  apt-get -y install tightvncserver

  apt autoremove -y 

  systemctl set-default multi-user.target
  systemctl stop gdm.service
  systemctl stop gdm3
  systemctl stop chrome-remote-desktop
  systemctl disable gdm.service
  systemctl disable gdm3
  systemctl disable chrome-remote-desktop

  echo
  echo "Setup up User Account..."
  groupadd chrome-remote-desktop

  echo $SCRIPT_VERSION":"$MY_NAME":"$MY_IP > $WDIR/done

fi

#Check if the script version has changed

LAST_SCRIPT_VERSION=`cut -f1 -d: $WDIR/done`

if [ "$LAST_SCRIPT_VERSION" != "$SCRIPT_VERSION" ]; then

  echo "New Version"

fi	


echo $SCRIPT_VERSION":"$MY_NAME":"$MY_IP > $WDIR/done
echo "*** "
echo "*** Startup Script finished"
echo "*** "`cat $WDIR/done`
echo "*** "
