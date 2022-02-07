#!/bin/bash
#
# Creates gcp project
#
BIN_DIR=$(dirname ${BASH_SOURCE[0]})
cd $BIN_DIR

project_id="$1"
project_name="$2"
if [[ -z "$project_id" || -z "$project_name" ]]; then
  echo "Usage: projectid projectName"
  exit 1
fi

current_user=$(gcloud config list --format="value(core.account)")
billing_account=$(gcloud alpha billing accounts list --format="value(name)")
[ -n "$billing_account" ] || { echo "ERROR you must setup a billing account in the Web console before continuing"; exit 3; }
echo "billing_account for $current_user is $billing_account"

project_count=$(gcloud projects list --filter="id=$project_id" --format="value(projectId)" | wc -l)
if [ $project_count -eq 0 ]; then
  gcloud projects create $project_id
else
  echo "gcp project $project_id already exists"
fi
gcloud config set project $project_id

echo "add this project to billing account so services can start being enabled"
set -x
gcloud beta billing projects list --billing-account=$billing_account
gcloud beta billing projects link $project_id --billing-account=$billing_account
gcloud beta billing projects list --billing-account=$billing_account
set +x

echo "enable apis for fleet workload identity"
gcloud services enable --project=$project_id \
   container.googleapis.com \
   gkeconnect.googleapis.com \
   gkehub.googleapis.com \
   cloudresourcemanager.googleapis.com \
   iam.googleapis.com \
   anthos.googleapis.com

