#!/bin/bash
# This script shows the vlan identifier/ip and subnet masks to help figuring out firewall configuration for pipeline workers

CLUSTERNAMES=${CLUSTERNAMES:-"otc-pw-fra02-prod otc-pw-fra04-prod otc-pw-fra05-prod"}

echo "Cluster name: identifier & subnet mask"
for aCluster in $CLUSTERNAMES; do
  for vlanId in $(ibmcloud ks cluster-get ${aCluster} --showResources | grep -Pzo '.*VLAN ID(.*\n)*' | grep -a 'true' | awk '{print $1}'); do
    #echo "VLAN ID: $vlanId"
	additionalPrimary=$(ibmcloud sl vlan detail ${vlanId} | grep 'ADDITIONAL_PRIMARY')
    echo "$aCluster: $(echo $additionalPrimary | awk '{print $2}') & $(echo $additionalPrimary | awk '{print $3}')"
  done
done;
