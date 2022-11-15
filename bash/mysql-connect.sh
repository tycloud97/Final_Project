#!/bin/bash

function connectToDB {
    kubectl port-forward service/mysql 3306:3306 &
    
    sleep 2

    while true
    do
        nc -vz 127.0.0.1 3306
        sleep 2
    done
}

function cleanup {
    pkill -f mysql-connect
}

trap cleanup EXIT

connectToDB &>/dev/null &

mysql -h 127.0.0.1 -u root -p