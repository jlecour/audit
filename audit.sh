#!/bin/bash

date=$(date +%F-%H:%M)
hostname=$(hostname -f || hostname)
_DEST_FILE="audit.${hostname}.${date}.md"
exec > >(tee -a $_DEST_FILE) 2>&1

run_command() {
    local command=$($* 2> /dev/null)
    if [ -z "$command" ]; then
        echo ":warning: Warning ! :warning:"
        echo -e "\n\`\`\`bash"
        echo "Command \"$*\" did not return any result."
        echo -e "\`\`\`"
    else
        echo -e "\n\`\`\`bash"
        echo "$ $*"
        $*
        echo -e "\`\`\`"
    fi
}

search_packages() {
    local packages=$*
    local command=$($_PKGMNGR_LIST | grep -E $packages)
    if [ -z "$command" ]; then
        echo "Search for \"$packages\" packages did not return any result(s)."
    else
        echo -e "\n\`\`\`bash"
        #echo $command
        $_PKGMNGR_LIST | grep -E $packages
        echo -e "\`\`\`"
    fi
}

if [[ $EUID -ne 0 ]]; then
    echo -e "\`\`\`"
    echo -e "This script as better results when run as root."
    echo -e "With non-root user, it will still work, but some check won't pass."
    echo -e "\`\`\`"
fi

uptime=$(uptime -p | sed "s/up/up since/")
kernel_release=$(uname -r)
system_info=$(uname -a)
kernel_version=$(uname -v)

echo -e "Hi! My name is ${hostname}" and I am ${uptime}".  "
if [[ -z `/usr/bin/lsb_release -d | grep -i debian` ]]; then
    _OS="Debian"
    _OS_VERSION=`lsb_release -d|sed "s/Description:\t//"`
    _PKGMNGR_LIST="dpkg -l"
    echo -e "I'm running with $_OS_VERSION, with a ${kernel_release} kernel (version ${kernel_version}).\n"
elif [[ -z `/usr/bin/lsb_release -d | grep -i ubuntu` ]]; then
    _OS="Ubuntu"
    _OS_VERSION=`lsb_release -d|sed "s/Description:\t//"`
    _PKGMNGR_LIST="dpkg -l"
    echo -e "I'm running with $_OS_VERSION, with a ${kernel_release} kernel (version ${kernel_version}).\n"
elif [[ -f "/etc/centos-release" ]]; then
    _OS="Centos"
    _PKGMNGR_LIST="yum list installed"
    _OS_VERSION=`cat /etc/centos-release`
    echo -e "I'm running $_OS_VERSION with a ${kernel_release} kernel.\n"
else
    echo -e "I'm running a ${kernel_release} kernel (version ${kernel_version}).\n"
    _OS="Unknown Linux"
    exit 0
fi

echo -e "\n## System"
echo -e "* Name: ${hostname}"
echo -e "* Uptime: $(uptime -p | sed "s/up//")."
echo -e "* $_OS version: $_OS_VERSION"
echo -e "* Kernel: ${system_info}"

echo -e "\n## CPU"
echo -e "* Processor model: $(cat /proc/cpuinfo |grep "model name" | uniq | sed 's/model name.*\: //')"
echo -e "* Core(s): $(cat /proc/cpuinfo |grep -c processor)"

echo -e "\n## Memory"
run_command "free -m"

echo -e "\n## Disk(s)"
run_command "df -h"
run_command "cat /etc/fstab"
run_command "mount"

echo -e "\n## Kernel"
echo "#### Loaded kernel"
run_command "uname -a"
echo "#### Available kernel"
if [[ $_OS = "Debian" ]]; then
    echo -e "\`\`\`bash"
    echo "$ $_PKGMNGR_LIST|grep linux-image | grep -v rc | grep -v meta-package |awk '{print $2\" (\"$3\")\"}'"
    $_PKGMNGR_LIST|grep linux-image | grep -v rc | grep -v meta-package |awk '{print $2" ("$3")"}'
    echo -e "\`\`\`"
fi

if [[ $_OS = "Debian" ]]; then
    echo -e "\n## Debian sources"
    run_command "cat /etc/apt/sources.list"
    run_command "grep . -Hr /etc/apt/sources.list.d/"
fi

echo -e "\n## Network"
echo "#### Networking package(s) installed"
search_packages "vlan|iproute|ifenslave"
run_command "cat /etc/network/interfaces"
run_command "cat /etc/network/interfaces.d/*"
run_command "/sbin/ip a"
run_command "netstat -tnlp"
run_command "cat /etc/hosts"

echo -e "\n## Firewall"
run_command "/sbin/iptables -L -n"
run_command "/sbin/iptables -L -n -t nat"

echo -e "\n## HTTP"
echo "#### HTTP package(s) installed"
search_packages "apache|nginx|lighttp|varnish|haproxy|php"

echo -e "\n## Database"
echo "#### Database package(s) installed"
search_packages "mysql|maria|percona|postgre|sqlite"
run_command "if [[ -f \"/etc/mysql/my.cnf\" ]]; then cat /etc/mysql/my.cnf | grep -v \"#\" ; fi"
run_command "if [[ -f \"/etc/mysql/my.cnf\" ]]; then MYSQL_DATADIR=$(cat /etc/mysql/my.cnf |grep datadir | awk '{print $3}') && ionice -c 3 du -sh $MYSQL_DATADIR ; fi"

echo -e "\n## NoSQL"
echo "#### NoSQL package(s) installed"
search_packages "memcache|redis"

echo -e "\n## Email"
echo "#### Email package(s) installed"
search_packages "mail"

echo -e "\n## Virtualization"
echo "#### Virtualization package(s) installed"
search_packages "xen|virt|qemu|kvm"

echo -e "\n## Supervision"
echo "#### Supervision package(s) installed"
search_packages "nagios|nrpe|icinga|munin|netdata|cacti"

echo -e "\n## Cron"
run_command "ls -lR /etc/cron*"
run_command "grep . -Hr /var/spool/cron/crontabs/"

echo -e "\n## Users"
run_command "getent passwd"

echo -e "\n## Process"
echo "#### Systemctl"
run_command "systemctl list-units"
run_command "pstree"
run_command "ps faux"

echo -e "\n## Backup"
echo "#### Backup package(s) installed"
search_packages "rsync|backup|bacula"
run_command "find / -maxdepth 3 -type d -name '*backup*'"

echo -e "\n## Misc"
echo "#### Other interresting package(s)"
search_packages "sudo|ldap|ftp|bind|puppet|ansible|git|etckeeper|nfs|rabbit|supervisor|kibana|elastic"

echo -e "\n## Docker containers"
echo "#### Docker ps"
run_command "docker ps -a"

echo -e "\n## Docker images"
echo "#### Docker images"
run_command "docker images"
