#!/bin/bash

oc label mcp worker machineconfiguration.openshift.io/role=worker
oc patch mcp worker --type=merge -p '{"spec":{"maxUnavailable":1}}'
oc patch  schedulers.config.openshift.io cluster --type=merge -p '{"spec":{"mastersSchedulable":false}}'
oc -n openshift-machine-api scale --replicas=3 $(oc -n openshift-machine-api get machineset -o name)

while true; do
	if oc get csr 2>/dev/null | grep -q Pending; then
		oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
	fi
	sleep 10
done
