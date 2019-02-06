#/bin/bash

GC_PROJECT=${GOOGLE_CLOUD_PROJECT:-"$(gcloud config get-value core/project --quiet)"}

tmp=""
read -p "GCE Project ($GC_PROJECT): " tmp
GC_PROJECT=${tmp:-$GC_PROJECT}

if [ -z "$GC_PROJECT" ]; then
  echo " Project is not set"
  exit 1
fi

gsutil ls gs://$GC_PROJECT-crd-startup-script 2>1 >/dev/null
retval=$?
if [ "$retval" = "1" ]; then
  gsutil mb gs://$GC_PROJECT-crd-startup-script 
fi
gsutil cp crd-startup*.sh gs://$GC_PROJECT-crd-startup-script/
exit 0
