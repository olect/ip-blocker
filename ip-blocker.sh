#!/bin/sh
####################################
#
# IP-BLOCKER - IPTables wrapper for block/unblock
# Author: Ole Chr. Thorsen 2014
# GitHub: https://github.com/olect
# Repo: https://github.com/olect/ip-blocker
#
####################################

function is_sudo()
{
    if ! $(sudo -n true > /dev/null 2>&1); then
            return 1
    else
            return 0
    fi
    return 1
}

if ! is_sudo; then
	echo -e "\n * You don't have the right permission. Try using sudo" >&2; exit 1
fi

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function is_numeric()
{
	local num=$1
	local stat=1
	if [[ $num =~ ^[0-9]+$ ]]; then
		stat=$?
	fi
	return $stat
}

function chain_exists() {
    if ! $(sudo iptables -nL $1 > /dev/null 2>&1); then
            return 1
    else
            return 0
    fi
    return 1
}

function install
{
	if chain_exists "BANNED"; then 
		echo "Installation is already complete!";
	else
		sudo iptables -N BANNED
		sudo iptables -F BANNED
		sudo iptables -N BANNEDLOG
		sudo iptables -F BANNEDLOG
		sudo iptables -A BANNEDLOG -j LOG --log-prefix "BANNED:" --log-level 6
		sudo iptables -A BANNEDLOG -j DROP
		sudo iptables -A INPUT -j BANNED
		
		#Uncomment to help prevent DDOS attacks...
		#sudo iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m limit --limit 50/minute --limit-burst 200 -j ACCEPT
		#sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -m limit --limit 50/second --limit-burst 50 -j ACCEPT
	fi
}   # end of install

function block
{
	if [ -n "$1" ]; then
		if valid_ip $1; then 
			NOW=$(date +"%Y-%m-%d %k:%M:%S")
		    sudo flock -w 5 /var/lock/iptables -c "iptables -A BANNED -s $1 -m comment --comment \"$NOW - Possibly attacker\" -j BANNEDLOG"
		    echo "Blocked: [$1] added to iptables chain: BANNED"
		else
			echo "Error: '$1' is not a valid ip address" >&2; exit 1
		fi
	else
		echo -e "\n * Usage: $0 block {ipaddress}"
	fi
}   # end of install

function list
{
	sudo iptables -vnL BANNED --line-numbers
}   # end of install

function unblock()
{
	if [ -n "$1" ]; then
		if is_numeric $1; then
			sudo flock -w 5 /var/lock/iptables -c "iptables -D BANNED $1"
			echo "Unblocked: Removed rule number $1"
		else
			if valid_ip $1; then

        		rulesString=$($0 list | grep $1| grep -o ^[0-9]*)
        		rules=()
			while read -r line; do
   				rules+=("$line")
			done <<< "$rulesString"
			ruleCount=${#rules[@]}
        		if [[ "$ruleCount" -gt "1" ]]; then
        			echo "Found $ruleCount ip addresses matching $1"
				ipString=$($0 list | grep $1 | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
				ipArr=()
				removeString="0.0.0.0"
				while read -r line; do
					if [ $line != $removeString ]; then
						ipArr+=("$line")
					fi
				done <<< "$ipString"
				printf "%s\n" "${ipArr[@]}"
        			exit 1
        		elif [[ "$ruleCount" -eq "1" ]]; then
        			match=${rules[0]}
				sudo flock -w 5 /var/lock/iptables -c "iptables -D BANNED $match"
				echo "Unlocked: Removed rule with ip $1"
        		else
        			echo "No matches found on $1"
        			exit 1
        		fi
			else 
				echo "Error: '$1' not numberic or a valid ip address!" >&2; exit 1
			fi
		fi
	else
		echo -e "\n * Usage: $0 unblock {num|ipaddress}"
	fi
		
}

case "$1" in
'install')
  install
  ;;
'list')
  list
  ;;
'block')
  block $2
  ;;
 'unblock')
  unblock $2
  ;;
*)
	if chain_exists "BANNED"; then 
  		echo -e "\n * Usage: $0 {block|unblock|list}"
	else
		echo -e "\n * Run: '$0 install' the first time to setup"
	fi
esac
