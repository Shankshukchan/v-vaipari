#!/bin/bash

echo "Configuring MongoDB as a replica set for Prisma..."

# Check if replica set is already configured in the config
if grep -q "replSetName:" /etc/mongod.conf; then
    echo "Replica set is already configured in /etc/mongod.conf."
else
    echo "Adding replica set configuration to /etc/mongod.conf..."
    echo -e "\nreplication:\n  replSetName: rs0" >> /etc/mongod.conf
fi

echo "Restarting MongoDB service..."
systemctl restart mongod

echo "Waiting for MongoDB to restart..."
sleep 3

echo "Initiating the replica set..."
mongosh --eval 'rs.initiate()'

echo "Done! You can now test your API again."
