#!/bin/bash
# Functions #########################################################

help(){
echo "

Options :
		- --create : lancer des conteneurs

		- --drop : supprimer les conteneurs créer par le deploy.sh
	
		- --infos : caractéristiques des conteneurs (ip, nom, user...)

		- --start : redémarrage des conteneurs

		- --ansible : déploiement arborescence ansible

		- --configureSSH : configuration de SSH and install key to the remote server

"
}

createNodes() {
	# définition du nombre de conteneur
	nb_machine=1
	[ "$1" != "" ] && nb_machine=$1
	# setting min/max
	min=1
	max=0

	mainuser=$USER
	# récupération de idmax
	idmax=`docker ps -a --format '{{ .Names}}' | awk -F "-" -v user="$mainuser" '$0 ~ user"-debian" {print $3}' | sort -r |head -1`
	# redéfinition de min et max
	min=$(($idmax + 1))
	max=$(($idmax + $nb_machine))

	password="sa3tHJ3/KuYvI"
	ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N ''

	# lancement des conteneurs
	for i in $(seq $min $max);do
		docker run -tid --privileged --publish-all=true -v /srv/data:/srv/html -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name $mainuser-debian-$i -h $mainuser-debian-$i priximmo/buster-systemd-ssh
		docker exec -ti $mainuser-debian-$i /bin/sh -c "useradd -m -p $password $mainuser"
		docker exec -ti $mainuser-debian-$i /bin/sh -c "mkdir  ${HOME}/.ssh && chmod 700 ${HOME}/.ssh && chown $mainuser:$mainuser $HOME/.ssh"
		docker cp $HOME/.ssh/id_rsa.pub $mainuser-debian-$i:$HOME/.ssh/authorized_keys
		docker exec -ti $mainuser-debian-$i /bin/sh -c "chmod 600 ${HOME}/.ssh/authorized_keys && chown $mainuser:$mainuser $HOME/.ssh/authorized_keys"
		docker exec -ti $mainuser-debian-$i /bin/sh -c "echo '$mainuser   ALL=(ALL) NOPASSWD: ALL'>>/etc/sudoers"
		docker exec -ti $mainuser-debian-$i /bin/sh -c "service ssh start"
		echo "Conteneur $mainuser-debian-$i créé"
	done
	infosNodes	
}

dropNodes(){
	echo "Suppression des conteneurs..."
	docker rm -f $(docker ps -a | grep $mainuser-debian | awk '{print $1}')
	echo "Fin de la suppression"
}

startNodes(){
	echo ""
	docker start $(docker ps -a | grep $mainuser-debian | awk '{print $1}')
  for conteneur in $(docker ps -a | grep $mainuser-debian | awk '{print $1}');do
		docker exec -ti $conteneur /bin/sh -c "service ssh start"
  done
	echo ""
}

createAnsible(){
	echo ""
  	ANSIBLE_DIR="ansible_dir"
  	mkdir -p $ANSIBLE_DIR
	mkdir -p $ANSIBLE_DIR/host_vars
  	mkdir -p $ANSIBLE_DIR/group_vars
  	mkdir -p $ANSIBLE_DIR/roles
  	touch $ANSIBLE_DIR/ansible.cfg
  	echo "all:" > $ANSIBLE_DIR/00_inventory.yml
	echo "  vars:" >> $ANSIBLE_DIR/00_inventory.yml
    echo "    ansible_python_interpreter: /usr/bin/python3" >> $ANSIBLE_DIR/00_inventory.yml
  	echo "  hosts:" >> $ANSIBLE_DIR/00_inventory.yml
	value=0
  	for conteneur in $(docker ps -a | grep $mainuser-debian | awk '{print $1}');do
		value=$(($value + 1))
		echo "    $mainuser-debian-$value:" >> $ANSIBLE_DIR/00_inventory.yml
		mkdir -p $ANSIBLE_DIR/host_vars/$mainuser-debian-$value
    	#docker inspect -f '    {{.NetworkSettings.IPAddress }}:' $conteneur >> $ANSIBLE_DIR/00_inventory.yml
		docker inspect -f 'ansible_host: {{.NetworkSettings.IPAddress }}' $conteneur >> $ANSIBLE_DIR/host_vars/$mainuser-debian-$value/main.yml
		echo "ansible_user: $mainuser" >> $ANSIBLE_DIR/host_vars/$mainuser-debian-$value/main.yml
  	done
  	mkdir -p $ANSIBLE_DIR/host_vars
  	mkdir -p $ANSIBLE_DIR/group_vars
	echo "ansible_user: $mainuser" > $ANSIBLE_DIR/group_vars/all.yml
  	mkdir -p $ANSIBLE_DIR/roles
  	touch $ANSIBLE_DIR/ansible.cfg
  	echo "[defaults]" > $ANSIBLE_DIR/ansible.cfg
  	echo "inventory = ./00_inventory.yml" >> $ANSIBLE_DIR/ansible.cfg
  	echo "roles_path = ./roles" >> $ANSIBLE_DIR/ansible.cfg
  	echo "ansible_python_interpreter = /usr/bin/python3" >> $ANSIBLE_DIR/ansible.cfg
  	echo ""
}

configureSSH(){
	echo ""
	echo "Configuration de SSH"
	echo ""
	apt-get -y install sshpass
	echo ""
	echo "Installation de sshpass"
	echo ""
	ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N ''
	eval `ssh-agent`
	ssh-add
	echo ""
	echo "Install key on containers"
	for conteneur in $(docker ps -a | grep $mainuser-debian | awk '{print $1}');do
		srv=$(docker inspect -f '{{.NetworkSettings.IPAddress }}' $conteneur)
		echo "First container : $srv"
		sshpass -p 'vagrant' ssh-copy-id -o StrictHostKeyChecking=no $mainuser@$srv 
	done
	echo ""
	echo "Fin de la configuration de SSH"
	echo ""

}

infosNodes(){
	echo ""
	echo "Informations des conteneurs : "
	echo ""
	for conteneur in $(docker ps -a | grep $mainuser-debian | awk '{print $1}');do      
		docker inspect -f '   => {{.Name}} - {{.NetworkSettings.IPAddress }}' $conteneur
	done
	echo ""
}

# Let's Go !!! #######################################################

#si option --create
if [ "$1" == "--create" ];then
	createNodes $2

# si option --drop
elif [ "$1" == "--drop" ];then
	dropNodes

# si option --start
elif [ "$1" == "--start" ];then
	startNodes

# si option --ansible
elif [ "$1" == "--ansible" ];then
	createAnsible

# si option --configureSSH
elif [ "$1" == "--configureSSH" ];then
	configureSSH

# si option --infos
elif [ "$1" == "--infos" ];then
	infosNodes

# si aucune option affichage de l'aide
else
	help
fi