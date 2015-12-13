# GLS 20151127 New bind9 server checks.  Terminates script if bind9 status is invalid.

function GetNamedStatus {
sudo service bind9 status | grep Active | cut -f1-6 -d' ' | sed 's/ *//g'
}
NamedStatus=$(GetNamedStatus)

echo ''
echo "============================================"
echo "Checking status of bind9...                  "
echo "============================================"

if [ $NamedStatus != 'Active:active(running)' ]
then
	echo ''
	echo "bind9 is NOT RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "bind9 status ...                             "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "bind9 status incorrect.                      "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with bind9 and retry script.  "
	echo "============================================"
	echo ''
else
	echo ''
	echo "bind9 is RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "bind9 status ...                             "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "bind9 status complete.                       "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
	echo ''
fi

echo "============================================"
echo "Status check of bind9 completed.        "
echo "============================================"
echo ''

# GLS 20151128 New bind9 status check end.

sleep 5

clear

