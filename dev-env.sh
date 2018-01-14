#!/bin/bash

docker run --privileged -itd -h dev-env --name dev-env \
           -v $HOME/work:/work:z \
           -v $HOME/.ssh:/home/docker/.ssh:z \
           --net=dev-net \
           --ip=10.1.1.11 \
           dev-env
