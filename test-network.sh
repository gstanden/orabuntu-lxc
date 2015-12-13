echo ''
echo "==============================================="
echo "Verify network up....                          "
echo "==============================================="
echo ''

function CheckNetworkUp {
ping -c 3 lxcora0 | grep packet | cut -f3 -d',' | sed 's/ //g'
}
NetworkUp=$(CheckNetworkUp)
while [ "$NetworkUp" !=  "0%packetloss" ] && [ "$n" -lt 5 ]
do
NetworkUp=$(CheckNetworkUp)
let n=$n+1
done

if [ "$NetworkUp" != '0%packetloss' ]
then
echo ''
echo "=============================================="
echo "WAN is not up or is hiccuping badly.          "
echo "Script exiting.                               "
echo "ping google.com test must succeed             "
echo "Address network issues/hiccups & rerun script."
echo "=============================================="
exit
else
echo ''
echo "=============================================="
echo "Network ping test verification complete.      "
echo "=============================================="
echo ''
fi

