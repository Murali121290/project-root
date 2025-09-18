#!/bin/bash
TAG="jenkins-sonar-minikube-demo"
INSTANCES=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=${TAG}" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
if [ -z "$INSTANCES" ]; then echo "No running instances found"; exit 0; fi
aws ec2 stop-instances --instance-ids $INSTANCES
echo "Stop request submitted: $INSTANCES"
