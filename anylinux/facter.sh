       			 	sudo yum -y install which ruby curl tar
       	 	
				echo ''
       			 	echo "=============================================="
       			 	echo "Facter package prerequisites installed.       "
       		 		echo "=============================================="
	
				sleep 5

				clear

       			 	echo ''
       			 	echo "=============================================="
       			 	echo "Build and install Facter from Ruby Gems...    "
       			 	echo "=============================================="
       			 	echo ''

				sleep 5

				mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/facter
				cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/facter
				curl -s http://downloads.puppetlabs.com/facter/facter-2.4.4.tar.gz | sudo tar xz; sudo ruby facter*/install.rb

