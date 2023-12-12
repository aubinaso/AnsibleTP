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


	# récupération de idmax
	idmax=`docker ps -a --format '{{ .Names}}' | awk -F "-" -v user="$USER" '$0 ~ user"-debian" {print $3}' | sort -r |head -1`
	# redéfinition de min et max
	min=$(($idmax + 1))
	max=$(($idmax + $nb_machine))
    port=8080

	# lancement des conteneurs
	for i in $(seq $min $max);do
		#docker run -tid --privileged --publish-all=true -v /srv/data:/srv/html -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name $USER-debian-$i -h $USER-debian-$i priximmo/buster-systemd-ssh
        docker run -tid --privileged -p $port:80  -v /srv/data:/srv/html -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name $USER-debian-$i -h $USER-debian-$i priximmo/buster-systemd-ssh
		docker exec -ti $USER-debian-$i bash -c "useradd -m -p sa3tHJ3/KuYvI $USER"
        docker exec -ti $mainuser-debian-$i bash -c "sed -i 's/#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config"
        docker exec -ti $mainuser-debian-$i bash -c "sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config"
        docker exec -ti $mainuser-debian-$i bash -c  "sed -i 's/.*stretch-back.*$//' /etc/apt/sources.list"
		docker exec -ti $USER-debian-$i bash -c "mkdir  ${HOME}/.ssh && chmod 700 ${HOME}/.ssh && chown $USER:$USER $HOME/.ssh"
	    docker cp $HOME/.ssh/id_rsa.pub $USER-debian-$i:$HOME/.ssh/authorized_keys
	    docker exec -ti $USER-debian-$i bash -c "chmod 600 ${HOME}/.ssh/authorized_keys && chown $USER:$USER $HOME/.ssh/authorized_keys"
		docker exec -ti $USER-debian-$i bash -c "echo '$USER   ALL=(ALL) NOPASSWD: ALL'>>/etc/sudoers"
		docker exec -ti $USER-debian-$i bash -c "service ssh start"
		echo "Conteneur $USER-debian-$i créé"
        port=$(($port + 1))
	done
	infosNodes	
}

dropNodes(){
	echo "Suppression des conteneurs..."
	docker rm -f $(docker ps -a | grep $USER-debian | awk '{print $1}')
	echo "Fin de la suppression"
}

startNodes(){
	echo ""
	docker start $(docker ps -a | grep $USER-debian | awk '{print $1}')
  for conteneur in $(docker ps -a | grep $USER-debian | awk '{print $1}');do
		docker exec -ti $conteneur bash -c "service ssh start"
  done
	echo ""
}

createAnsible(){
	echo ""
  	ANSIBLE_DIR="ansible_dir"
  	mkdir -p $ANSIBLE_DIR
	mkdir -p $ANSIBLE_DIR/host_vars
    mkdir -p $ANSIBLE_DIR/group_vars/apache
    mkdir -p $ANSIBLE_DIR/group_vars/mariadb
	echo "ansible_user: $USER" > $ANSIBLE_DIR/group_vars/all.yml
    echo "ansible_host_list:" >> $ANSIBLE_DIR/group_vars/all.yml
    touch  $ANSIBLE_DIR/group_vars/apache/main.yml
    touch  $ANSIBLE_DIR/group_vars/mariadb/main.yml
  	mkdir -p $ANSIBLE_DIR/roles
  	touch $ANSIBLE_DIR/ansible.cfg
  	echo "all:" > $ANSIBLE_DIR/00_inventory.yml
	echo "  vars:" >> $ANSIBLE_DIR/00_inventory.yml
    echo "    ansible_python_interpreter: /usr/bin/python3" >> $ANSIBLE_DIR/00_inventory.yml
  	echo "  children:" >> $ANSIBLE_DIR/00_inventory.yml
    echo "    apache:" >> $ANSIBLE_DIR/00_inventory.yml
    echo "      hosts:" >> $ANSIBLE_DIR/00_inventory.yml
    echo "    mariadb:" >> $ANSIBLE_DIR/00_inventory.yml
    echo "      hosts:" >> $ANSIBLE_DIR/00_inventory.yml
    echo "  hosts:" >> $ANSIBLE_DIR/00_inventory.yml
	value=0
  	for conteneur in $(docker ps -a | grep $USER-debian | awk '{print $1}');do
		server_name=$(docker inspect -f '{{.Config.Hostname }}' $conteneur)
        echo "    $server_name:" >> $ANSIBLE_DIR/00_inventory.yml
		mkdir -p $ANSIBLE_DIR/host_vars/$server_name
    	#docker inspect -f '    {{.NetworkSettings.IPAddress }}:' $conteneur >> $ANSIBLE_DIR/00_inventory.yml
		docker inspect -f 'ansible_host: {{.NetworkSettings.IPAddress }}' $conteneur >> $ANSIBLE_DIR/host_vars/$server_name/main.yml
		echo "ansible_user: $USER" >> $ANSIBLE_DIR/host_vars/$server_name/main.yml
        echo "ansible_fqdn: $server_name" >> $ANSIBLE_DIR/host_vars/$server_name/main.yml
        srv=$(docker inspect -f '{{.NetworkSettings.IPAddress }}' $conteneur)
        echo "- $srv" >> $ANSIBLE_DIR/group_vars/all.yml
        ssh $srv sed -i 's/.*stretch-back.*$//' /etc/apt/sources.list
        echo "$srv $server_name" >> /tmp/file.txt
  	done
    for conteneur in $(docker ps -a | grep $USER-debian | awk '{print $1}');do
        server_name=$(docker inspect -f '{{.Config.Hostname }}' $conteneur)
        docker cp /tmp/file.txt $server_name:$HOME/
        docker exec -ti $server_name bash -c  "cat $HOME/file.txt >> /etc/hosts"
    done
    rm /tmp/file.txt
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
	apt-get install sshpass
	echo ""
	echo "Installation de sshpass"
	echo ""
	ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N ''
	eval `ssh-agent`
	ssh-add
	echo ""
	echo "Install key on containers"
	for conteneur in $(docker ps -a | grep $USER-debian | awk '{print $1}');do
		srv=$(docker inspect -f '{{.NetworkSettings.IPAddress }}' $conteneur)
		echo "Install key on $srv"
		sshpass -p 'vagrant' ssh-copy-id -o StrictHostKeyChecking=no $USER@$srv 
	done
	echo ""
	echo "Fin de la configuration de SSH"
	echo ""

}

infosNodes(){
	echo ""
	echo "Informations des conteneurs : "
	echo ""
	for conteneur in $(docker ps -a | grep $USER-debian | awk '{print $1}');do      
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