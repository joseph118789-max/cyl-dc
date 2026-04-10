#!/bin/bash
cd "$(dirname "$0")"

TERRAFORM_PATH="$(pwd)/terraform/deployment"

ansible-playbook -i inventory/inventory.ini playbooks/terraform-apply.yml -e terraform_base_path="$TERRAFORM_PATH"