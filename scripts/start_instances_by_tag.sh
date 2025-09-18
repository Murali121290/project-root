#!/bin/bash
TAG="jenkins-sonar-minikube-demo"
INSTANCES=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=${TAG}" "Name=instance-state-name,Values=stopped" --query 'Reservations[*].Instances[*].InstanceId' --output text)
if [ -z "$INSTANCES" ]; then echo "No stopped instances found"; exit 0; fi
aws ec2 start-instances --instance-ids $INSTANCES
echo "Start request submitted: $INSTANCES"
