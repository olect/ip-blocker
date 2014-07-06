ip-blocker
==========

Simple IPTables wrapper - Makes block/unblock tasks easier

Working with IPTables can sometimes become a pain when you just want to perform a simple task like blocking an IP (ex. an attacker)

I hate writing a lot in my *NIX terminal when performing sysadm task that should be simple.

Be warned! This script is just for block, unblock and listing your blocked ip's. 

Setting up
==========

Enter terminal and type (or copy/paste)

	git clone https://github.com/olect/ip-blocker.git /tmp/ip-blocker
	cp /tmp/ip-blocker/ip-blocker.sh /usr/bin/ip-blocker
	chmod a+x /usr/bin/ip-blocker
	rm -Rf /tmp/ip-blocker

Make sure you have `sudo` rights

And you are ready to go

While in terminal, type `ip-blocker` and you should get:

	* Usage: /usr/bin/ip-blocker {block|unblock|list}

Blocking
--------

	$ ip-blocker block 127.0.0.1

Not a good idea btw, blocking all incoming from your loopback-interface :-p

Unblocking
----------

	$ ip-blocker unblock 127.0.0.1

Thus allowing incoming on all ports from `127.0.0.1`

OR

	$ ip-blocker unblock 2

Thus removing rule number 2, see `ip-blocker list` for rulenumbers
