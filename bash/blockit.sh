#! /bin/bash
# Takes a list of sites from a text file called sites
# and blocks access to them for a certain number of 
# minutes. 
#
# Use --add / -a followed by the number of minutes
# to add a block. 
#
# Use --check / -c to check if the sites should still be blocked.
# This would ordinarily be done on the crontab.
#
# Currently this script must be run as root, or via sudo.

# What arguments do we pass?
while [ "$1" != "" ]; do
    case $1 in
        -a | --add )            shift
				minutes=$1
                                ;;
        -c | --check )		check=1
                                ;;
    esac
    shift
done

NOW=`date +%s`

if [[ "$check" == 1 ]]; then
	# Compare the current time against the control time.
	THEN=`cat control`

	# In case we've got crontab edits
	crontab -l | sed '/###START-blockit/,/###END-blockit/d' > cron
	test "$NOW" -ge "$THEN" && ( sed -i '/###START-blockit/,/###END-blockit/d' /etc/hosts; > control; crontab cron; echo "Unblocking sites"; )
	rm cron
fi

if [[ "$minutes" > 0 ]]; then
	# Remove any existing blocks, instructions.
	sed -i '/###START-blockit/,/###END-blockit/d' /etc/hosts
	> control

	# Keep track of when we should remove these lines from the hosts file.
	SECONDS=$(($minutes*60))
	THEN=$(($NOW+$SECONDS))
	echo $THEN > control

	# Edit the hosts file
	echo '###START-blockit.sh' >> /etc/hosts
	for i in $(cat sites); do echo "127.0.0.1 $i" >> /etc/hosts; done
	echo '###END-blockit.sh' >> /etc/hosts
	echo "These sites will be unblocked after $minutes minutes."

	# Update the crontab
	(crontab -l; echo '###START-blockit.sh'; echo "* * * * * cd `pwd`/; sudo ./blockit.sh -c"; echo '###END-blockit.sh') | crontab -

fi
