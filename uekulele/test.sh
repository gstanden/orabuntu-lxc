function CheckCgconfigRunning {
        sudo service cgconfig status
}
CgconfigRunning=$(CheckCgconfigRunning)

if [ $CgconfigRunning != 'Running' ]
then
	echo $CgconfigRunning
#       sudo service cgconfig start
else
        echo Service cgconfig status:  $CgconfigRunning
fi

