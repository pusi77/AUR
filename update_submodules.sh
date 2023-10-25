#!/bin/bash

for submodule in $(git submodule status | awk '{print $2}')
do
    cd "$submodule" || exit
    echo "Pulling $submodule"
    git checkout master
    git pull
    cd ..
done
