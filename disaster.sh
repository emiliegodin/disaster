#! /bin/bash
log() {
	echo $(date --rfc-3339=seconds):$1
}

test_ping() {
	log "disabling ping"
	echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all
	sleep $(shuf -i 15-25 -n 1)
	log "enabling ping"
	echo "0" > /proc/sys/net/ipv4/icmp_echo_ignore_all
}

test_tomcat() {
	log "stopping tomcat"
	sudo -u tomcat-8.5 ~tomcat-8.5/bin/shutdown.sh 2>/dev/null
	sleep $(shuf -i 15-25 -n 1)
	log "starting tomcat"
	sudo -u tomcat-8.5 ~tomcat-8.5/bin/startup.sh 2>/dev/null
}

test_mysql() {
	log "stopping mysql"
	service mysql stop  2>/dev/null
	sleep $(shuf -i 15-25 -n 1)
	log "starting mysql"
	service mysql start	 2>/dev/null
}

test_port() {
	sudo ufw allow 22/tcp > /dev/null 2>&1
	echo "y" | sudo ufw enable > /dev/null 2>&1
	log "blocking 8080/tcp"
	sudo ufw deny 8080/tcp > /dev/null 2>&1
	sleep $(shuf -i 15-25 -n 1)
	log "allowing 8080/tcp"
	sudo ufw allow 8080/tcp > /dev/null 2>&1
	sudo ufw disable > /dev/null 2>&1
	sudo ufw deny 22/tcp > /dev/null 2>&1
}

test_ram() {
	log "loading RAM"
	timeout $(shuf -i 15-25 -n 1) bash -c -- 'while true; do tail /dev/zero ; done'> /dev/null 2>&1
	log "freeing RAM"
}

test_cpu() {
	log "loading CPU"
	timeout $(shuf -i 15-25 -n 1) yes > /dev/null
	log "freeing CPU"
}


test_oome() {
	log "Calling jsp-oome"
	curl http://poeubuntuvb2:8080/jsp-oome/helloFromServlet
	log "freeing CPU"
}

test_disk() {
	log "Loading disk /disk1"
	yes > /disk1/plop 2> /dev/null
	sleep $(shuf -i 15-25 -n 1)
	rm /disk1/plop
	log "Freeing disk /disk1"
}

test_sender() {
	log "Sending error to trap1"
	zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k trap1 -o 1
}



if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi


(test_ping) &
(test_tomcat) &
(test_mysql) &
(test_oome) &

log "launched 1"
wait
log "done 1"

(test_port) &
(test_ram) &
(test_cpu) &
(test_disk) &
(test_sender) &

log "launched 2"
wait
log "done 2"


