# Stop docker and delete br0
apt-get install bridge-utils



echo -e "------------------------------------------------------------------------"
echo -e "     _            _               _          _     _       "
echo -e "  __| | ___   ___| | _____ _ __  | |__  _ __(_) __| | __ _(_)_ __   __ _"
echo -e " / _- |/ _ \ / __| |/ / _ \ -__| | -_ \| -__| |/ _- |/ _- | | -_ \ / _- |"
echo -e "| (_| | (_) | (__|   <  __/ |    | |_) | |  | | (_| | (_| | | | | | (_| |"
echo -e " \__,_|\___/ \___|_|\_\___|_|    |_.__/|_|  |_|\__,_|\__, |_|_| |_|\__, |"
echo -e "                                                     |___/         |___/"
echo -e "------------------------------------------------------------------------"
echo -e "Docker Bridging - https://github.com/argosax-reborn"
echo -e "Crée un pont entre host et container docker"
echo -e "(docker)--(pipework)--(dockerhost)--(LAN)--(ROUTER)--(WAN)"

echo -e "------------------------------------------------------------------------"
echo -e "    ----------------------------------------------------------------    "
echo -e "Nettoyage bridges"
ip link set dev br0 down
brctl delif docker0 eth0
brctl delbr docker0
brctl delif br0 eth0
brctl delbr br0
iptables -t nat -F POSTROUTING
cp /etc/default/docker /etc/default/docker.bak
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "ip forwarding : ok"

echo -e "Ajout de br0"
brctl addbr br0

echo -e "Quelle IP pour br0 : "
read bridgeip

echo -e "Quel masque pour br0 :  au format CIDR ex: /24"
echo -e "Par defaut : /24"
read msk
if [ -z $msk]
then msk="/24"
fi
bridgeip=$bridgeip$msk
ip addr add $bridgeip dev br0
ip link set dev br0 up

echo -e "Verification de docker et des containers lances"
value=$(echo $(docker ps | awk -F " " '{print $1}' | sed -n '1!p'))
service docker start
if [ -z $value ]
then
	echo -e "----------------------------------------------"
	echo -e "Aucun container lance !"
	echo -e "----------------------------------------------"
	docker images | awk -F " " '{print $1,$3,$12}'
	echo -e "----------------------------------------------"

	echo -e "Lancer un container : "
	read container_name
	echo -e "Avec quels parametres : ex: -d ou -itd, ect..."
	echo -e "Si le container ne redemarre pas, mauvais parametres !"
	read params
	echo -e "Processus a laisser en foreground"
	echo -e "ex: /usr/sbin/apache2ctl -D FOREGROUND"
	read fg_process
	echo -e "----------------------------------------------"
	dkr_pid=$(docker run $params $container_name $fg_process | cut -d' ' -f1)
	echo -e "----------------------------------------------"

else
	echo -e "----------------------------------------------"
	docker ps | awk -F " " '{print $1,$3,$12,$13}'
	echo -e "----------------------------------------------"
	echo -e "Entrer le nom d'un container a externaliser : "
	echo -e "Il peut d agir de son ID ou de son NAME"
	read container_name
	echo  -e "Le container va etre detruit puis relance"
	dkr_img=$(docker inspect --format='{{ .Image}}' $container_name)
	docker kill $container_name

	echo -e "Avec quels parametres : ex: -d ou -itd, ect..."
	echo -e "Si le container ne redemarre pas, mauvais parametres !"
	read params
	echo -e "Processus a laisser en foreground"
	echo -e "ex: /usr/sbin/apache2ctl -D FOREGROUND"
	read fg_process
	dkr_pid=$(docker run $params $dkr_img $fg_process | cut -d' ' -f1)
	container_name=$(docker inspect --format=' {{ .Name}} ' $dkr_pid)
	container_name=$(echo $container_name | sed 's/[/]//g')
	echo $container_name

fi

echo -e "----------------------------------------------"
echo -e "Adresse IP souhaitee pour "$container_name" : "

echo -e "Elle doit etre sur le meme reseau que "$bridgeip" : "
echo -e "----------------------------------------------"
read container_ip
echo -e "----------------------------------------------"
echo -e "Masque different ? : default "$msk
read msk
if [ -z $msk]
then msk="/24"
fi
echo -e "----------------------------------------------"
echo -e "Interface sur laquelle ponter : ex: eth0"
read real_iface
if [ -z $real_iface]
then real_iface="eth0"
fi

container_ip=$container_ip$msk
echo -e "----------------------------------------------"
echo -e "Pontage entre br0 et $real_iface"
brctl addif br0 $real_iface
echo -e "----------------------------------------------"

echo -e "Pontage entre le container et br0"
echo -e "----------------------------------------------"
pipework br0 $dkr_pid $container_ip
echo -e "------------------------------------------------"
echo -e "Container name : "$container_name" avec l'ip "$container_ip
echo -e "------------------------------------------------"
echo -e "Ping vers "$container_ip" devrait fonctionner :D"

#Ajouter cette ligne dans /etc/default/docker
#Pour demarrer tous les containers sur br0
#Redemarrer le service docker puis le script
#Cette operation n est a effectuer qu une fois
#echo 'DOCKER_OPTS="--bridge=br0"' >> /etc/default/docker
