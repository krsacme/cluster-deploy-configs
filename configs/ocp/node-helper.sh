#!/bin/bash

config="$HOME/.ssh/config"
if [ -f $config ]; then
	rm -rf $config
fi
: >$config

nodes=$(oc get nodes -o jsonpath='{range .items[*].metadata}{.name}{"\n"}{end}')
for i in ${nodes}; do
	name=$(oc get nodes $i -o jsonpath='{.metadata.name}');
	ip=$(oc get nodes $i -o jsonpath='{.status.addresses[0].address}')
	echo "$name  $ip"
	echo "Host $name">>$config
	echo "  Hostname $ip">>$config
	echo "  User core">>$config
	echo "  StrictHostKeyChecking no">>$config
	echo "  UserKnownHostsFile=/dev/null">>$config
done
chmod 400 $config
