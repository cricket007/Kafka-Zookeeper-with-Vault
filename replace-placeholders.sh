#!/usr/bin/env bash
# This script can be used to replace all the placeholders so that Packer and Terraform can be run to create and run the products in AWS
# This script has been tested with the following operating systems:
#
# 1. Mac OS X 10.13.2
set -e

readonly DEFAULT_INSTALL_PATH="/opt/consul"
readonly DEFAULT_CONSUL_USER="consul"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SYSTEM_BIN_DIR="/usr/local/bin"

readonly SUPERVISOR_DIR="/etc/supervisor"
readonly SUPERVISOR_CONF_DIR="$SUPERVISOR_DIR/conf.d"

readonly SCRIPT_NAME="$(basename "$0")"

function print_usage {
  echo
  echo "Usage: install-consul [OPTIONS]"
  echo
  echo "This script can be used to install Consul and its dependencies. This script has been tested with Ubuntu 16.04 and Amazon Linux."
  echo
  echo "Options:"
  echo
  echo -e "  --file\t\The path and name containing the JSON objects to be used to replace the placeholders. (see the vars-example.conf example) Required."
  echo
  echo "Example:"
  echo
  echo "  replace-placeholders --file /file-path/vars.conf"
}

function log {
  local readonly level="$1"
  local readonly message="$2"
  local readonly timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local readonly message="$1"
  log "INFO" "$message"
}

function log_warn {
  local readonly message="$1"
  log "WARN" "$message"
}

function log_error {
  local readonly message="$1"
  log "ERROR" "$message"
}

function assert_not_empty {
  local readonly arg_name="$1"
  local readonly arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

# escape forward slashes and remove surrounding quotes
function trim-value {
  temp=$(remove-quotes "$1")
  escape-slashes "$temp"
}

# escape forward slashes
function escape-slashes {
  echo "$1" | sed 's;/;\\/;g'
}

# remove surrounding quotes
function remove-quotes {
  temp="${1%\"}"
  echo "${temp#\"}"
}

# Set the internal variables from the config file
function read-conf-file {
  local readonly file="$1"

  pem_file_location=$(jq '.pem_file_location' $file)
  pem_file_location=$(remove-quotes "$pem_file_location")
  log_info "pem_file_location is: "$pem_file_location

  pem_file=$(jq '.pem_file' $file)
  pem_file=$(trim-value "$pem_file")
  log_info "pem_file is: "$pem_file

  aws_account_id=$(jq '.aws_account_id' $file)
  aws_account_id=$(trim-value "$aws_account_id")
  log_info "aws_account_id is: "$aws_account_id

  arn_for_terraform_iam_role=$(jq '.arn_for_terraform_iam_role' $file)
  arn_for_terraform_iam_role=$(trim-value "$arn_for_terraform_iam_role")
  log_info "arn_for_terraform_iam_role is: "$arn_for_terraform_iam_role

  aws_access_key=$(jq '.aws_access_key' $file)
  aws_access_key=$(trim-value "$aws_access_key")
  log_info "aws_access_key is: "$aws_access_key

  aws_secret_key=$(jq '.aws_secret_key' $file)
  aws_secret_key=$(trim-value "$aws_secret_key")
  log_info "aws_secret_key is: "$aws_secret_key

  s3_state_bucket_name=$(jq '.s3_state_bucket_name' $file)
  s3_state_bucket_name=$(trim-value "$s3_state_bucket_name")
  log_info "s3_state_bucket_name is: "$s3_state_bucket_name

  access_key_pair=$(jq '.access_key_pair' $file)
  access_key_pair=$(trim-value "$access_key_pair")
  log_info "access_key_pair is: ""$access_key_pair"


}


# Replace placeholders in the Packer .json files
function replace-packer-file-placeholders {
sed -i -- 's/<Access key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/bastion_base.json
sed -i -- 's/<Secret key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/bastion_base.json
sed -i -- 's/<your account ID>/'"$aws_account_id"'/g' $path/Packer/bastion_base.json
sed -i -- 's/<ARN for role defined in Terraform>/'"$arn_for_terraform_iam_role"'/g' $path/Packer/bastion_base.json

sed -i -- 's/<Access key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/Zookeeper/zookeeper.json
sed -i -- 's/<Secret key for user allowed to assume role defined in Terraform>/'"$aws_secret_key"'/g' $path/Packer/Zookeeper/zookeeper.json
sed -i -- 's/<ARN for role defined in Terraform>/'"$arn_for_terraform_iam_role"'/g' $path/Packer/Zookeeper/zookeeper.json

sed -i -- 's/<Access key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/Consul/consul.json
sed -i -- 's/<Secret key for user allowed to assume role defined in Terraform>/'"$aws_secret_key"'/g' $path/Packer/Consul/consul.json
sed -i -- 's/<ARN for role defined in Terraform>/'"$arn_for_terraform_iam_role"'/g' $path/Packer/Consul/consul.json

sed -i -- 's/<Access key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/Vault/vault.json
sed -i -- 's/<Secret key for user allowed to assume role defined in Terraform>/'"$aws_secret_key"'/g' $path/Packer/Vault/vault.json
sed -i -- 's/<ARN for role defined in Terraform>/'"$arn_for_terraform_iam_role"'/g' $path/Packer/Vault/vault.json

sed -i -- 's/<Access key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/Management\ Tools/management-tools.json
sed -i -- 's/<Secret key for user allowed to assume role defined in Terraform>/'"$aws_secret_key"'/g' $path/Packer/Management\ Tools/management-tools.json
sed -i -- 's/<ARN for role defined in Terraform>/'"$arn_for_terraform_iam_role"'/g' $path/Packer/Management\ Tools/management-tools.json

sed -i -- 's/<Access key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/Kafka/kafka.json
sed -i -- 's/<Secret key for user allowed to assume role defined in Terraform>/'"$aws_secret_key"'/g' $path/Packer/Kafka/kafka.json
sed -i -- 's/<ARN for role defined in Terraform>/'"$arn_for_terraform_iam_role"'/g' $path/Packer/Kafka/kafka.json

sed -i -- 's/<Access key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/Kafka\ Connect/kafka_connect.json
sed -i -- 's/<Secret key for user allowed to assume role defined in Terraform>/'"$aws_secret_key"'/g' $path/Packer/Kafka\ Connect/kafka_connect.json
sed -i -- 's/<ARN for role defined in Terraform>/'"$arn_for_terraform_iam_role"'/g' $path/Packer/Kafka\ Connect/kafka_connect.json

log_info "Packer .json fle Placeholder replacement complete!"

}

# Replace placeholders in the run script files
function replace-run-script-placeholders {
sed -i -- 's/<your .pem file>/'"$pem_file"'/g' $path/Packer/Zookeeper/install-zookeeper/conf_zookeeper.py
sed -i -- 's/<your .pem file>/'"$pem_file"'/g' $path/Packer/Consul/install-consul/conf_consul.py
sed -i -- 's/<your .pem file>/'"$pem_file"'/g' $path/Packer/Vault/install-vault/conf_vault.py
sed -i -- 's/<your .pem file>/'"$pem_file"'/g' $path/Packer/Management\ Tools/install-tools/conf_tools.py
sed -i -- 's/<your .pem file>/'"$pem_file"'/g' $path/Packer/Kafka/install-kafka/conf_kafka.py
sed -i -- 's/<your .pem file>/'"$pem_file"'/g' $path/Packer/Kafka\ Connect/install-kafka_connect/conf_kafka_connect.py

sed -i -- 's/<Access key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/Consul/run-consul/run-consul
sed -i -- 's/<Secret key for user allowed to assume role defined in Terraform>/'"$aws_secret_key"'/g' $path/Packer/Consul/run-consul/run-consul

sed -i -- 's/<Access key for user allowed to assume role defined in Terraform>/'"$aws_access_key"'/g' $path/Packer/Vault/run-vault/run-vault
sed -i -- 's/<Secret key for user allowed to assume role defined in Terraform>/'"$aws_secret_key"'/g' $path/Packer/Vault/run-vault/run-vault

log_info "Script Placeholder replacement complete!"

}

# Replace placeholders in the Terraform files
function replace-terraform-placeholders {
sed -i -- 's/<your account ID>/'"$aws_account_id"'/g' $path/Terraform/envs/test/main.tf
sed -i -- 's/<ARN for IAM Role predefined to allow Terraform to create everything>/'"$arn_for_terraform_iam_role"'/g' $path/Terraform/envs/test/main.tf
sed -i -- 's/<ARN for IAM Role predefined to allow Terraform to create everything>/'"$arn_for_terraform_iam_role"'/g' $path/Terraform/envs/test/variables.tf

sed -i -- 's/<your account ID>/'"$aws_account_id"'/g' $path/Terraform/modules/zookeeper_ASG/zookeeper_ASG.tf
sed -i -- 's/<your account ID>/'"$aws_account_id"'/g' $path/Terraform/modules/consul_ASG/consul_ASG.tf
sed -i -- 's/<your account ID>/'"$aws_account_id"'/g' $path/Terraform/modules/vault_ASG/vault_ASG.tf
sed -i -- 's/<your account ID>/'"$aws_account_id"'/g' $path/Terraform/modules/management_ASG/management_ASG.tf
sed -i -- 's/<your account ID>/'"$aws_account_id"'/g' $path/Terraform/modules/kafka_ASG/kafka_ASG.tf
sed -i -- 's/<your account ID>/'"$aws_account_id"'/g' $path/Terraform/modules/kafka_connect_ASG/kafka_connect_ASG.tf
sed -i -- 's/<your account ID>/'"$aws_account_id"'/g' $path/Terraform/modules/management_bastion/management_bastion.tf

sed -i -- 's/<name for your state bucket>/'"$s3_state_bucket_name"'/g' $path/Terraform/envs/test/main.tf


sed -i -- 's/<key pair for instance access>/'"$access_key_pair"'/g' $path/Terraform/modules/management_bastion/management_bastion.tf

log_info "Terraform Placeholder replacement complete!"

}

# Add secret files
function insert-pem_file {
    cp "$pem_file_location/$pem_file" $path/Packer/Zookeeper/install-zookeeper/
    cp "$pem_file_location/$pem_file" $path/Packer/Consul/install-consul/
    cp "$pem_file_location/$pem_file" $path/Packer/Vault/install-vault/
    cp "$pem_file_location/$pem_file" $path/Packer/Management\ Tools/install-tools/
    cp "$pem_file_location/$pem_file" $path/Packer/Kafka/install-kafka/
    cp "$pem_file_location/$pem_file" $path/Packer/Kafka\ Connect/install-kafka_connect/

    log_info ".pem file placement complete!"
}

function replace {
  local file=''

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --file)
        file="$2"
        shift
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        log_error "Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac

    shift
  done

  assert_not_empty "--file" "$file"

  log_info "Starting placeholder replacement"
  log_info "variable file location: "$file


  read-conf-file $file
  replace-packer-file-placeholders
  replace-run-script-placeholders
  replace-terraform-placeholders
  insert-pem_file

  log_info "Placeholder replacement complete!"
}

pem_file_location=""
pem_file=""
aws_account_id=""
arn_for_terraform_iam_role=""
aws_access_key=""
aws_secret_key=""
s3_state_bucket_name=""
access_key_pair=""

path=$(pwd)
log_info "base path is: "$path

replace "$@"