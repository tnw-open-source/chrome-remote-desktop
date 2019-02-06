# chrome-remote-desktop

gcloud-setup.sh  -- Configures a gcloud based VM

update-bucket.sh -- Writes and updates of crd-startup*,sh to the approriate GS bucket

crd-startup*.sh  -- GCE instance startup scripts for the various Linux flavors 

-----

Experimentation, notes, scripts to get a CRD instance running in gcloud

Starting Points:

[Link to information #1](https://groups.google.com/forum/#!searchin/gce-discussion/chrome$20remote$20desktop%7Csort:date/gce-discussion/tN9oZs8xWps/b2PtOBTeAQAJ)

[Link to information #2](http://timbot-inc.blogspot.com/2015/11/cloud-workstation-howto-chromebook.html)

[Link to information #3](https://medium.com/google-cloud/linux-gui-on-the-google-cloud-platform-800719ab27c5)

[Link to information #4](https://support.google.com/chrome/answer/1649523?hl=en)


Once you get your GCE instance set up the big steps are:
For Debian:
```bash
# Install CRD
wget "https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"
sudo dpkg --install chrome-remote-desktop_current_amd64.deb
sudo apt-get -f install
# goto http://remotedesktop.google.com/headless  to get a command like below to start CRD service from SSH:
# /opt/google/chrome-remote-desktop/start-host --code="xxxxxxxxxxxxxxxxxxxxxxxxxxxx" --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --pin 123456 --name=my_gce_crd
# restart the desktop in the desired resolution
/opt/google/chrome-remote-desktop/chrome-remote-desktop -k
/opt/google/chrome-remote-desktop/chrome-remote-desktop --start -s 3840x2160
```
