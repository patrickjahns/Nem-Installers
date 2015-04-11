#!/bin/bash
# Safe-nem-install.sh
# This script will attempt to install NEM on Ubuntu 14.04.
# No guarantees that it will even work. Use at your own risk.
# It was written to easily install NEM on a free Amazon EC2 VPS
# NEVER EVER expose your private keys on a VPS
# Use a VPS server for secure remote harvesting only

cd ~/
if [[ -z "$1" ]]; then
    echo "No version provided - fetching latest version"
    wget -q http://bob.nem.ninja/version.txt
    version=$(cat 'version.txt')
    echo "latest version is $version"
else
    version=$1
fi
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin;
gpg --keyserver keys.gnupg.net --recv-key 0xA46494A9 > /dev/null 2>&1 || { echo "Could not receive public key."; exit 1; }
rm -rf ncc-nis-$version.* nem.tgz version.txt
echo "Downloading ncc-nis-$version.tgz"
wget -v http://bob.nem.ninja/nis-ncc-$version.{tgz,tgz.sig}
tar_sig=$(gpg --verify nis-ncc-$version.tgz.sig > /dev/null 2>&1; echo $?)
if [[ sha_sum -ne 0 || tar_sig -ne 0 || chg_sig -ne 0 ]]; then
        rm -f nis-ncc-$version.*
        echo "ERROR: Signature mismatch."
        exit 1
else
	echo "Downloaded ncc-nis-$version.tgz and GPG signature OK"
	tar xvfz nis-ncc-$version.tgz
	echo "Uncompressed ncc-nis-$version to package"
fi

echo "Type the name you would like for your server followed by [ENTER]:"

read bootname

#Generates a random key

hash=sha256sum	#Hash method used
length=64	#Length of output in chars

#Get Random Data
time=$(date +%N%s%u%w%Z)

#Get password
pass=$(\
echo $(dmesg | $hash) $(cat /proc/cpuinfo | $hash) $(cat /proc/meminfo | $hash) $(cat /proc/interrupts | $hash) $(cat /proc/stat | $hash) $(cat /proc/iomem | $hash) $(cat /proc/ioports | $hash) $(cat /proc/mounts | $hash) $(df -h | $hash) $(free -b | $hash) $(vmstat -s | $hash) $(vmstat -d | $hash) $(tail -n 500 /var/log/udev | $hash) $(id | $hash) $(last | $hash) $(who | $hash) $(groups | $hash) $(ps -aefw | $hash) $(fuser -mv / 2>&1 | $hash) $(netstat -s | $hash) $(route -n | $hash) $(dd if=/dev/urandom bs=256 count=4 2>&1 | $hash) \
| $hash )


time=$(echo \
	$time\
	$(date +%N%s%u%w%Z) \
	$(dd if=/dev/urandom bs=256 count=4 2>&1 | $hash -b)\
	| $hash)

#Output Random Key
#echo $time $pass | $hash | head -c $length

bootkey=$(echo $time $pass | $hash | head -c $length)

# Add bootkey to config.properties
echo "nis.bootName = $bootname" >> package/nis/config-user.properties
echo "nis.bootKey = $bootkey" >> package/nis/config-user.properties
echo "nis.shouldAutoHarvestOnBoot = false" >> package/nis/config-user.properties

echo "Added your bootName $bootname and a random bootkey $bootkey to package/nis/config.properties"

#Put scripts in /usr/local/sbin to start and stop NCC and NIS
echo "#!/bin/bash" >> StopNem
echo "pkill -f 'org.nem.core.deploy.CommonStarter' && while pgrep -f 'org.nem.core.deploy.CommonStarter' ; do sleep .1; done" >> StopNem
chmod +x StopNem
sudo mv StopNem /usr/local/sbin/StopNem

echo '#!/bin/bash
cd ~/package/nis
java -Xms512M -Xmx768M -cp ".:./*:../libs/*" org.nem.core.deploy.CommonStarter > /dev/null 2>&1 &
echo "NIS started"
cd ~/' > StartNis
chmod +x StartNis
sudo mv StartNis /usr/local/sbin/StartNis

echo '#!/bin/bash
cd ~/package/ncc
java -cp ".:./*:../libs/*" org.nem.core.deploy.CommonStarter > /dev/null 2>&1 &
echo "NCC started"
cd ~/' > StartNcc
chmod +x StartNcc
sudo mv StartNcc /usr/local/sbin/StartNcc



echo '#!/bin/bash
if [[ -z "$1" ]]; then
    echo "No version provided - fetching latest version"
    wget -q http://bob.nem.ninja/version.txt
    version=$(cat 'version.txt')
    echo "latest version is $version"
else
    version=$1
fi
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin;
gpg --keyserver keys.gnupg.net --recv-key 0xA46494A9 > /dev/null 2>&1 || { echo "Could not recieve public key."; exit 1; }
rm -rf ncc-nis-$version.* nem.tgz
echo "Downloading ncc-nis-$version.tgz"
wget -v http://bob.nem.ninja/nis-ncc-$version.{tgz,tgz.sig}
tar_sig=$(gpg --verify nis-ncc-$version.tgz.sig > /dev/null 2>&1; echo $?)
if [[ sha_sum -ne 0 || tar_sig -ne 0 || chg_sig -ne 0 ]]; then
        rm -f nis-ncc-$version.*
        echo "ERROR: Signature mismatch."
        exit 1
else
	echo "Downloaded ncc-nis-$version.tgz and GPG signature OK"
	echo "Moving current package to package-bak.tgz"
	echo "Stopping NIS and NCC"
	pkill -f 'org.nem.core.deploy.CommonStarter' && while pgrep -f 'org.nem.core.deploy.CommonStarter' ; do sleep .1; done
	rm package-bak.tgz
	cp package/nis/config-user.properties ~/
	tar cvfz package-bak.tgz package/
	rm -r package/
	tar xvfz nis-ncc-$version.tgz
	echo "Uncompressed ncc-nis-$version to package"
	echo "Moving old config.properties to new config.properties"
	mv config-user.properties package/nis/config-user.properties
	echo "Finished upgrading NEM"
	echo "Run StartNis and if needed StartNcc"
fi' > UpgradeNem
chmod +x  UpgradeNem
sudo mv UpgradeNem /usr/local/sbin/UpgradeNem


echo 'The server is ready to start'
echo 'Type StartNis to run NIS'
echo 'Type StartNcc to run NCC'
echo 'Type StopNem to stop NIS and NCC'
echo 'Type UpgradeNem to upgrade NIS and NCC'


