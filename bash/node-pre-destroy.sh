#!/bin/bash

cd ansible/

read -p "Enter node name: " NAME

ENDPOINT_IP=$(awk '/\[endpoint\]/ { getline; print }' inventories/inventory.ini)
STORAGE_IP=$(awk '/\[storage\]/ { getline; print }' inventories/inventory.ini)

NODE_TYPE=$(
    echo $NAME | awk '{
        x = substr($0, 0, 3);
        if ( x == "kwn" ) {
            print "wn";
        } else if ( x == "kcp" ) {
            print "cp";
        }
    }'
)

NODE_NUM=$(
    echo $NAME | awk '{
        x = substr($0, 5);
        print x;
    }'
)

VM_IP=$(
    awk -v type="$NODE_TYPE" -v num="$NODE_NUM" '
    /network_prefix/ {
        gsub(/"/, "", $3);
        prefix = $3;
    }
    
    $0 ~ type"_starting_ip" {
        gsub(/"/, "", $3);
        ip = prefix "" $3 + num;
        print ip;
    }
    ' ../terraform.tfvars
)

ansible-playbook -i $ENDPOINT_IP, playbooks/endpoint_hosts.yml --extra-vars="host_ip=$VM_IP host_type=worker host_name=$NAME host_state=absent"

kubectl drain $NAME --ignore-daemonsets --delete-emptydir-data
kubectl delete node $NAME

ansible-playbook -i $STORAGE_IP, playbooks/storage_hosts.yml --extra-vars="host_ip=$VM_IP host_type=k8s host_state=absent"

ansible-playbook playbooks/inventory.yml --extra-vars="host_type=worker host_ip=$VM_IP host_state=absent"