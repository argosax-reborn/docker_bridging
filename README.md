# docker_bridging
Permet de bridger facilement des containers et de leur attribuer une IP fixe du réseau de la machine hôte


##For what use ?
Can mount bridge interface, set static IP of br0, set container static IP and bridge container interface to br0
with pipework from jpetazzo -> https://github.com/jpetazzo/pipework


##Prerequisties
pipework with a ln -s in /usr/bin/ because the script calls for pipework
docker & bridge-utils
