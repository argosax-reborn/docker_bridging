# Stop docker and delete br0
export DEBIAN_FRONTEND=noninteractive
apt-get install -q -y bridge-utils
#echo -e "Docker Bridging - https://github.com/argosax-reborn"
#echo -e "Help to configure bridge across host and docker container"
#echo -e "(docker)--(pipework)--(dockerhost)--(LAN)--(ROUTER)--(WAN)"
function banner {
	clear
	echo -e "------------------------------------------------------------------------"
	echo -e "     _            _               _          _     _       "
	echo -e "  __| | ___   ___| | _____ _ __  | |__  _ __(_) __| | __ _(_)_ __   __ _"
	echo -e " / _- |/ _ \ / __| |/ / _ \ -__| | -_ \| -__| |/ _- |/ _- | | -_ \ / _- |"
	echo -e "| (_| | (_) | (__|   <  __/ |    | |_) | |  | | (_| | (_| | | | | | (_| |"
	echo -e " \__,_|\___/ \___|_|\_\___|_|    |_.__/|_|  |_|\__,_|\__, |_|_| |_|\__, |"
	echo -e "                                                     |___/         |___/"
	echo -e "------------------------------------------------------------------------"
	echo -e "------------------------------------------------------------------------"
	echo -e "    ----------------------------------------------------------------    "
}
banner
while [ -z $* ]
	do
	echo -e "-----------------------"
	echo -e "-i for interactive mode"
	echo -e "-p for parameter mode"
	echo -e "-----------------------"
	exit
done
case "$1" in
	-i)
echo -e "---------------------------------"
echo -e "        Interactive Mode         "
echo -e "---------------------------------"
echo -e "      Questions are asked        "
echo -e "     Responses are computed      "
echo -e " Bridging is made and configured "
echo -e "---------------------------------"
echo -e "        ... Nettoyage ...        "
echo -e "---------------------------------"
#ip link set dev br0 down
#brctl delif docker0 eth0
#brctl delbr docker0
#brctl delif br0 eth0
#brctl delbr br0
#iptables -t nat -F POSTROUTING
cp /etc/default/docker /etc/default/docker.bak
#echo 1 > /proc/sys/net/ipv4/ip_forward
echo -e "..."
#brctl addbr br0
banner
echo -e "Quelle IP pour br0 : "
read bridgeip
banner
echo -e "Quel masque pour br0 :  au format CIDR ex: /24"
echo -e "Par defaut : /24"
read msk
if [ -z $msk ]
then msk="/24"
fi
bridgeip=$bridgeip$msk
ip addr add $bridgeip dev br0
ip link set dev br0 up
banner
echo -e "Verification de docker et des containers lances"
value=$(echo $(docker ps | awk -F " " '{print $1}' | sed -n '1!p'))
service docker start
if [ -z $value ]
then
	banner
	echo -e "----------------------------------------------"
	echo -e "Aucun container lance !"
	echo -e "----------------------------------------------"
	docker images | awk -F " " '{print $1,$3,$12}'
	echo -e "----------------------------------------------"

	echo -e "Lancer un container : "
	read container_name
	banner
	echo -e "Avec quels parametres : ex: -d ou -itd, ect..."
	echo -e "Si le container ne redemarre pas, mauvais parametres !"
	read params
	banner
	echo -e "Processus a laisser en foreground"
	echo -e "ex: /usr/sbin/apache2ctl -D FOREGROUND"
	read fg_process
	echo -e "----------------------------------------------"
	dkr_pid=$(docker run $params $container_name $fg_process | cut -d' ' -f1)
	echo -e "----------------------------------------------"

else
	banner
	echo -e "----------------------------------------------"
	docker ps | awk -F " " '{print $1,$3,$12,$13}'
	echo -e "----------------------------------------------"
	echo -e "Entrer le nom d'un container a externaliser : "
	echo -e "Il peut d agir de son ID ou de son NAME"
	read container_name
	echo  -e "Le container va etre detruit puis relance"
	dkr_img=$(docker inspect --format='{{ .Image}}' $container_name)
	docker kill $container_name
	banner
	echo -e "Avec quels parametres : ex: -d ou -itd, ect..."
	echo -e "Si le container ne redemarre pas, mauvais parametres !"
	read params
	banner
	echo -e "Processus a laisser en foreground"
	echo -e "ex: /usr/sbin/apache2ctl -D FOREGROUND"
	read fg_process
	dkr_pid=$(docker run $params $dkr_img $fg_process | cut -d' ' -f1)
	container_name=$(docker inspect --format=' {{ .Name}} ' $dkr_pid)
	container_name=$(echo $container_name | sed 's/[/]//g')
	echo $container_name

fi

banner
echo -e "----------------------------------------------"
echo -e "Adresse IP souhaitee pour "$container_name" : "

echo -e "Elle doit etre sur le meme reseau que "$bridgeip" : "
echo -e "----------------------------------------------"
read container_ip
banner
echo -e "----------------------------------------------"
echo -e "Masque different ? : default "$msk
read msk
if [ -z $msk ]
then msk="/24"
fi
banner
echo -e "----------------------------------------------"
echo -e "Interface sur laquelle ponter : default : eth0"
read real_iface
if [ -z $real_iface ]
then real_iface="eth0"
fi

container_ip=$container_ip$msk
banner
echo -e "----------------------------------------------"
echo -e "Pontage entre br0 et $real_iface"
brctl addif br0 $real_iface
banner
echo -e "----------------------------------------------"

echo -e "Pontage entre le container et br0"
echo -e "----------------------------------------------"
pipework br0 $dkr_pid $container_ip
banner
echo -e "------------------------------------------------"
echo -e "Container name : "$container_name" avec l'ip "$container_ip
echo -e "------------------------------------------------"
echo -e "Ping vers "$container_ip" devrait fonctionner :D"

#Ajouter cette ligne dans /etc/default/docker
#Pour demarrer tous les containers sur br0
#Redemarrer le service docker puis le script
#Cette operation n est a effectuer qu une fois
#echo 'DOCKER_OPTS="--bridge=br0"' >> /etc/default/docker
;;
	-p)
		echo -e "---------------------------------"
		echo -e "Parameter Mode"
		echo -e "Use : launch docker_bridging"
		echo -e "with parameters in one-liner syle"
		echo -e "---------------------------------"
		echo -e "       PARAMETERS REQUIRED       "
		echo -e "---------------------------------"
		echo -e "OPTION		Description	  "
		echo -e "  -b		IP Address of bridge"
		echo -e "  -r		"
		echo -e "  -c		 my_container_id_or_name"
		echo -e "  -"

;;
	*)
		echo -e "Bad parameter !"
		echo -e "You should try -i or -p"
		echo -e "Now quitting..."
		exit 0
;;
esac
