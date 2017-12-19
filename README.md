# Kafka Zookeeper with Vault

![Image of Diagram] (design.png)


## Accelerator for running Kafka, Zookeeper, and Vault in AWS 
### About the Accelerator
- Packer files for the Bastion hosts, Management tools, Kafka, Zookeeper, and Vault servers
- Terraform files the Bastion hosts, Management tools, Kafka, Zookeeper, and Vault servers/ASG's
- Python scripts to start the applications on the servers

### Pre-Reqs
- Terraform installed
- Packer installed
- AWS CLI installed

### Getting Started Instructions
#### update the packer .json files
- TBD


#### update the terraform .tf files
- TBD

#### update the conf_*.py files
- TBD

### to-Do's
- put kafka-connect into proper ASG and get it installed
- create Vault and consul clusters
- Vault requires harcoded AWS keys in run-vault, this needs fixing
- create an initalisation script to update the user, role, and key info

### License
Copyright [2017] [Paul Pogonoski]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
