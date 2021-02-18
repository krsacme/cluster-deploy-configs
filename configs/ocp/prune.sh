#!/bin/bash

if [ ! -f /tmp/prune-copy.sh ]; then
        cat<<EOF>/tmp/prune-copy.sh
sudo podman system prune -fa
for i in $(podman images | grep jump | awk '{print $1":"$2}'); do podman rmi -f $i; done
EOF
fi

sleep 2
LIST=$(oc get nodes -o json | jq '.items[] .status.addresses[0].address' | tr -d '"')
for i in  $LIST; do echo "Node - ${i}"; scp /tmp/prune-copy.sh core@$i:/tmp/; ssh core@$i 'sudo bash /tmp/prune-copy.sh;'; done

