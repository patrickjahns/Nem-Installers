#!/bin/bash
#=======================================
# name		: install_nem.sh
# author 	: jadedjack
# author	: mr.pj
# date		: 20150414
# version	: 0.1.1
#========================================
# This script will attempt to install NEM on Ubuntu .
# No guarantees that it will even work. Use at your own risk.
# NEVER EVER expose your private keys on a VPS
# Use a VPS server for secure remote harvesting only
# For more Information visit
# https://forum.ournem.com/vps-nodes/how-to-easily-configure-and-install-nem-on-an-amazon-ec2-vps/
# Original upstart scripts by riegel, see:
# https://forum.ournem.com/technical-discussion/secure-nis-and-ncc-setup-on-linux/
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin;
INSTALL_DIR=/opt/nem
DATA_DIR=/var/lib/nem
CONFIG_DIR=/etc/nem

install_java_msg() {
	echo >&2 "It seems that Oracle Java 8 is not installed on your system"
	echo >&2 "NEM installer requires Oracle Java 8"
	echo >&2 "For information on how to install Orcale Java 8 please visit:"
	echo >&2 "https://github.com/jadedjack/Nem-Installers#how-can-i-install-oracle-java-8"
}

#check our user and if not root if we can use su/sudu
user="$(id -un 2>/dev/null || true)"
sh_c='bash -c'
if [ "$user" != 'root' ]; then
	if type -p sudo; then
		sh_c='sudo -E bash -c'
	elif type -p su; then
		sh_c='bash -c'
	else
		echo >&2 'Error: this installer needs the ability to run commands as root.'
		echo >&2 'We are unable to find either "sudo" or "su" available to make this happen.'
		exit 1
	fi
fi

#check if we already can find java
echo "Checking for Oracle Java 8"
if type -p java 1>/dev/null; then
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then  
    _java="$JAVA_HOME/bin/java"
else
	install_java_msg
	exit 1
fi

#check java jdk type and version
JAVA_VER=$(java -version 2>&1)
if [[ $JAVA_VER =~ .*java.* ]]; then
	#oracle java 
	JAVA_VER_NUMBER=$(java -version 2>&1 | sed 's/java version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q')
	
	#check if its java version 8
	if [[ "$JAVA_VER_NUMBER" != "18" ]]; then
		install_java_msg
		exit 1
	fi
else	
	install_java_msg
	exit 1
fi

echo "Java ok"

#check if nem is already installed 
if [ -d "$INSTALL_DIR" ]; then
	echo "A previous installation already exists in $INSTALL_DIR "
	echo "If you want to update, please use $INSTALL_DIR/update_nem.sh to update"
	exit 1
fi

#check if gpg is available
USEGPG=1
if ! type -p gpg 1>/dev/null; then
	echo 
	while true; do
		read -p "Couldn't find gpg, won't be able to check signature. Continue? [yes/no]" yn
		case $yn in
			[Yy]* ) USEGPG=0; break;;
			[Nn]* ) echo "please install gpg and run the script again"; exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
fi

echo "Checking for latest version"
#fetch current version
version=$(wget -qO- http://bob.nem.ninja/version.txt)
echo "Found version $version"

if [[ -z "$version" ]]; then
	echo "Couldn't fetch the current version number, please make sure you are connected to the internet"
	exit 1
fi

mkdir -p /tmp/neminstall
cd /tmp/neminstall

echo "Downloading ncc-nis-$version.tgz"
wget -v http://bob.nem.ninja/nis-ncc-$version.{tgz,tgz.sig}
if [[ "$USEGPG" == "1" ]]; then
	echo "Getting key for signature verification"
	gpg --keyserver keys.gnupg.net --recv-key 0xA46494A9 > /dev/null 2>&1 || { echo "Could not receive public key."; exit 1; }
	echo "Checking signature....."
	tar_sig=$(gpg --verify nis-ncc-$version.tgz.sig > /dev/null 2>&1; echo $?)
	if [[ tar_sig -ne 0 ]]; then
			rm -f nis-ncc-$version.*
			echo "ERROR: Signature mismatch."
			exit 1
	fi
fi


echo "Downloaded ncc-nis-$version.tgz and GPG signature OK"
echo "Please specify installation directory and press [ENTER]"
echo "Default directory is $INSTALL_DIR. For default just press [ENTER]"
read install_dir
if [[ -n $install_dir ]]; then
		INSTALL_DIR=$install_dir
fi

echo "Installing nem in $INSTALL_DIR and using $DATA_DIR for data"
tar xfz nis-ncc-$version.tgz
rm -rf nis-ncc-$version.tgz nis-ncc-$version.tgz.sig

#move files to proper directory
$sh_c "mkdir -p $INSTALL_DIR"
$sh_c "mkdir -p $DATA_DIR"
$sh_c "mv ./package/* $INSTALL_DIR"

#save version number
echo $version > "$INSTALL_DIR/VERSION"

#create config directory
$sh_c "mkdir -p $CONFIG_DIR"
$sh_c "mkdir -p $CONFIG_DIR/nis"
$sh_c "mkdir -p $CONFIG_DIR/ncc"
$sh_c "mkdir -p $CONFIG_DIR/mon"

# move config files to config directory
$sh_c "touch $INSTALL_DIR/nis/config-user.properties"
$sh_c "touch $INSTALL_DIR/ncc/config-user.properties"
$sh_c "mv $INSTALL_DIR/logalpha.properties $CONFIG_DIR/logalpha.properties"
$sh_c "mv $INSTALL_DIR/mon/config.properties $CONFIG_DIR/mon/config.properties"
$sh_c "mv $INSTALL_DIR/nix.logalpha.properties $CONFIG_DIR/nix.logalpha.properties"
$sh_c "mv $INSTALL_DIR/ncc/logalpha.properties $CONFIG_DIR/ncc/logalpha.properties"
$sh_c "mv $INSTALL_DIR/ncc/config.properties $CONFIG_DIR/ncc/config.properties"
$sh_c "mv $INSTALL_DIR/ncc/config-user.properties $CONFIG_DIR/ncc/config-user.properties"
$sh_c "mv $INSTALL_DIR/nis/logalpha.properties $CONFIG_DIR/nis/logalpha.properties"
$sh_c "mv $INSTALL_DIR/nis/db.properties $CONFIG_DIR/nis/db.properties"
$sh_c "mv $INSTALL_DIR/nis/config-user.properties $CONFIG_DIR/nis/config-user.properties"
$sh_c "mv $INSTALL_DIR/nis/config.properties $CONFIG_DIR/nis/config.properties"

# create links back to install dir
$sh_c "ln -s $CONFIG_DIR/logalpha.properties $INSTALL_DIR/logalpha.properties"
$sh_c "ln -s $CONFIG_DIR/mon/config.properties $INSTALL_DIR/mon/config.properties"
$sh_c "ln -s $CONFIG_DIR/nix.logalpha.properties $INSTALL_DIR/nix.logalpha.properties"
$sh_c "ln -s $CONFIG_DIR/ncc/logalpha.properties $INSTALL_DIR/ncc/logalpha.properties"
$sh_c "ln -s $CONFIG_DIR/ncc/config-user.properties $INSTALL_DIR/ncc/config-user.properties"
$sh_c "ln -s $CONFIG_DIR/ncc/config.properties $INSTALL_DIR/ncc/config.properties"
$sh_c "ln -s $CONFIG_DIR/nis/logalpha.properties $INSTALL_DIR/nis/logalpha.properties"
$sh_c "ln -s $CONFIG_DIR/nis/db.properties $INSTALL_DIR/nis/db.properties"
$sh_c "ln -s $CONFIG_DIR/nis/config-user.properties $INSTALL_DIR/nis/config-user.properties"
$sh_c "ln -s $CONFIG_DIR/nis/config.properties $INSTALL_DIR/nis/config.properties"
$sh_c "touch $CONFIG_DIR/keys"

#add users 
$sh_c "groupadd nem"
$sh_c "groupadd nis"
$sh_c "groupadd ncc"
$sh_c "adduser --system  --home $INSTALL_DIR/nis --shell /bin/bash --no-create-home --ingroup nis nis"
$sh_c "adduser --system  --home $INSTALL_DIR/ncc --shell /bin/bash --no-create-home --ingroup ncc ncc"
$sh_c "usermod -aG nem ncc"
$sh_c "usermod -aG nem nis"

#set proper permissions
$sh_c "chown -R root:nem $INSTALL_DIR"
$sh_c "chown -R root:nis $INSTALL_DIR/nis"
$sh_c "chown -R root:ncc $INSTALL_DIR/ncc"

$sh_c "chown -R root:nem $DATA_DIR"
$sh_c "mkdir -p $DATA_DIR/nis"
$sh_c "chown -R nis:nis $DATA_DIR/nis"

$sh_c "mkdir -p $DATA_DIR/ncc"
$sh_c "chown -R ncc:ncc $DATA_DIR/ncc"

$sh_c "chown nis:nis $CONFIG_DIR/keys"

$sh_c "chmod 0700 $CONFIG_DIR/keys"
$sh_c "chmod -R g-w $INSTALL_DIR"
$sh_c "chmod -R o-rwx $INSTALL_DIR"
$sh_c "chmod -R g-w $DATA_DIR"
$sh_c "chmod -R o-rwx $DATA_DIR"
$sh_c "chmod g+rx $INSTALL_DIR/*.sh"


#configure user settings
echo "Type the name you would like for your server followed by [ENTER]:"
read bootname

s_rand_string=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 )

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

# Add info to ncc config-user.properties
$sh_c "echo \"nem.folder = $DATA_DIR\" >> \"$CONFIG_DIR/ncc/config-user.properties\""

# Add info to nis config-user.properties
$sh_c "echo \"nem.folder = $DATA_DIR\" >> \"$CONFIG_DIR/nis/config-user.properties\""
$sh_c "echo \"nis.bootName = $bootname\" >> \"$CONFIG_DIR/nis/config-user.properties\""
$sh_c "echo \"nis.bootKey = $bootkey\" >> \"$CONFIG_DIR/nis/config-user.properties\""
$sh_c "echo \"nis.shouldAutoHarvestOnBoot = false\" >> \"$CONFIG_DIR/nis/config-user.properties\""

#install upstart scripts
echo "#!/bin/bash
# chkconfig: 2345 85 25
### BEGIN INIT INFO
# Provides: ncc 
# Required-Start: \$local_fs \$network \$nis 
# Required-Stop: \$local_fs \$network \$nis D
# Default-Start: 2 3 4 5 
# Default-Stop: 0 1 6
### END INIT INFO
export NCCPIDFILE=/var/run/ncc.pid 
export NEMROOT=$INSTALL_DIR 
export NCCUSER=ncc 

function start {
  test -s \$NCCPIDFILE && test -d /proc/\`cat \$NCCPIDFILE\` && exit 1
  touch \$NCCPIDFILE && chown \$NCCUSER:\$NCCUSER \$NCCPIDFILE || exit 2
  su -c 'echo -n Starting NCC:
         cd \$NEMROOT/ncc
         nohup java -cp \".:./*:../libs/*\" org.nem.deploy.CommonStarter >/dev/null 2>&1 &
         NCCPID=\"\$!\"
         if [ -n \"\$NCCPID\" ]
         then
           echo \[OK\]
           echo \"\$NCCPID\" >\$NCCPIDFILE
         else
           echo \[FAILED\]
           exit 3
         fi' \$NCCUSER
}
function stop {
  su -c 'echo -n Stopping NCC:
         kill \`cat \$NCCPIDFILE\`
         if [ \"\$?\" -eq 0 ]
         then
           echo \[OK\]
         else
           echo \[FAILED\]
           exit 4
         fi' \$NCCUSER
  rm -f \$NCCPIDFILE
}
case \"\$1\" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        sleep 2
        start
        ;;
  *)
        echo \$\"Usage: \$0 {start|stop|restart}\"
        exit 5
esac" > /tmp/neminstall/ncc
$sh_c "mv /tmp/neminstall/ncc /etc/init.d/ncc"

echo "#!/bin/bash
# chkconfig: 2345 80 30

### BEGIN INIT INFO
# Provides: nis
# Required-Start: \$local_fs \$network
# Required-Stop: \$local_fs \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
### END INIT INFO

export NISPIDFILE=/var/run/nis.pid
export NEMROOT=$INSTALL_DIR
export CONFIG_DIR=$CONFIG_DIR
export HARVEST=0 #0 don't harvest, 1 harvest
export KEYFILE=\$CONFIG_DIR/keys
export NISUSER=nis
export NISDATADIR=$DATA_DIR
export NISLOGDIR=\$NISDATADIR/nis/logs
export MAXRAM=1G

# If you have more than one account place private keys between quotes separated by space
# and remember to increase nis.unlockedLimit in $CONFIG_DIR/nis/config.properties accordingly

function start {
  su -c 'echo -n Starting NIS:
         PID=\`pgrep -n -u \$NISUSER java\`
         [ -n \"\$PID\" ] && exit 1
         cd \$NEMROOT/nis
         nohup java -Xms512M -Xmx\$MAXRAM -cp \".:./*:../libs/*\" org.nem.deploy.CommonStarter >/dev/null 2>&1 &
         sleep 10
         export NISLOGFILE=\`ls \$NISLOGDIR/nis-*.log.lck | cut -d. -f1,2\`
         [ ! -f \"\$NISLOGFILE\" ] && exit 4
         while true
         do
           PID=\`pgrep -n -u \$NISUSER java\`
           if [ -z \"\$PID\" ]
           then
             echo \[FAILED\]
             exit 3
           fi
           STARTED=\`grep -m 1 \" NEM Deploy is ready to serve\" \$NISLOGFILE\`
           if [ -n \"\$STARTED\" ]
           then
             echo \[OK\]
             break
           fi
           sleep 5
         done
		 if [[ \$HARVEST == 1 ]]; then
			echo \"starting harvesting\"
			 while read KEY
			 do
			   \$NEMROOT/harvest.sh \$KEY
			 done < \$KEYFILE
		 fi' \$NISUSER
}

function stop {
  su -c 'echo -n Stopping NIS:
         while true
         do
           PIDS=\`pgrep -u \$NISUSER java\`
           if [ -z \"\$PIDS\" ]
           then
             echo -n \[OK\]
             break
           fi
           for PID in \$PIDS
           do
             kill \$PID
           done
           sleep 5
         done
         echo' \$NISUSER
}

case \"\$1\" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        start
        ;;
  *)
        echo \$\"Usage: \$0 {start|stop|restart}\"
        exit 6
esac" > /tmp/neminstall/nis
$sh_c "mv /tmp/neminstall/nis /etc/init.d/nis"

echo "#!/bin/bash
# This script updates your current nem installation
export PATH=\$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin;
INSTALL_DIR=/opt/nem
CONFIG_DIR=/etc/nem

#check our user and if not root if we can use su/sudu
user=\"\$(id -un 2>/dev/null || true)\"
sh_c='bash -c'
if [ \"\$user\" != 'root' ]; then
	if type -p sudo; then
		sh_c='sudo -E bash -c'
	elif type -p su; then
		sh_c='bash -c'
	else
		echo >&2 'Error: this installer needs the ability to run commands as root.'
		echo >&2 'We are unable to find either \"sudo\" or \"su\" available to make this happen.'
		exit 1
	fi
fi

#possibly check if the nem directory exists?
if [ ! -d \"\$INSTALL_DIR\" ]; then
	echo \"Could not locate the nem install directory, please make sure it exists\"
	exit 1
fi

#check if gpg is available
USEGPG=1
if ! type -p gpg 1>/dev/null; then
	echo 
	while true; do
		read -p \"Couldn't find gpg, won't be able to check signature. Continue? [yes/no]\" yn
		case \$yn in
			[Yy]* ) USEGPG=0; break;;
			[Nn]* ) echo \"please install gpg and run the script again\"; exit;;
			* ) echo \"Please answer yes or no.\";;
		esac
	done
fi

#fetch current version
echo \"Fetching latest NEM version\"
version=\$(wget -qO- http://bob.nem.ninja/version.txt)

if [[ -z \$version ]]; then
	echo \"Couldn't fetch the current version number, please make sure you are connected to the internet\"
	exit 1
fi

installed_version=\$(cat \$INSTALL_DIR/VERSION)

if [[ \$version == \$installed_version ]]; then
	echo \"The latest nem version (\$installed_version) is already installed - exiting..\"
	exit 1
fi

echo \"Latest version is \$version\"
mkdir -p /tmp/neminstall
cd /tmp/neminstall

rm -rf ncc-nis-\$version.* 
echo \"Downloading ncc-nis-\$version.tgz\"
wget -v http://bob.nem.ninja/nis-ncc-\$version.{tgz,tgz.sig}
if [[ \"\$USEGPG\" == \"1\" ]]; then
	echo \"Getting key for signature verification\"
	gpg --keyserver keys.gnupg.net --recv-key 0xA46494A9 > /dev/null 2>&1 || { echo \"Could not receive public key.\"; exit 1; }
	echo \"Checking signature.....\"
	tar_sig=\$(gpg --verify nis-ncc-\$version.tgz.sig > /dev/null 2>&1; echo \$?)
	if [[ tar_sig -ne 0 ]]; then
			rm -f nis-ncc-\$version.*
			echo \"ERROR: Signature mismatch.\"
			exit 1
	fi
fi

echo \"Downloaded ncc-nis-\$version.tgz and GPG signature OK\"
echo \"Moving current package to package-bak.tgz\"
echo \"Stopping NIS and NCC\"
\$sh_c \"/etc/init.d/nis stop\"
\$sh_c \"/etc/init.d/ncc stop\"

tar xfz nis-ncc-\$version.tgz
echo \"Uncompressed ncc-nis-\$version - moving files to install dir\"
# remove config files
\$sh_c \"rm -rf \$INSTALL_DIR/*\"
\$sh_c \"mv package/* \$INSTALL_DIR\"
echo \$version > \"\$INSTALL_DIR/VERSION\"

echo \"Linking current property files\"
#removing config files
\$sh_c \"rm \$INSTALL_DIR/logalpha.properties\"
\$sh_c \"rm \$INSTALL_DIR/mon/config.properties\"
\$sh_c \"rm \$INSTALL_DIR/nix.logalpha.properties\"
\$sh_c \"rm \$INSTALL_DIR/ncc/logalpha.properties\"
\$sh_c \"rm \$INSTALL_DIR/ncc/config.properties\"
\$sh_c \"rm \$INSTALL_DIR/nis/logalpha.properties\"
\$sh_c \"rm \$INSTALL_DIR/nis/db.properties\"
\$sh_c \"rm \$INSTALL_DIR/nis/config.properties\"

# create links back to install dir
\$sh_c \"ln -s \$CONFIG_DIR/logalpha.properties \$INSTALL_DIR/logalpha.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/mon/config.properties \$INSTALL_DIR/mon/config.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/mon/config-user.properties \$INSTALL_DIR/mon/config-user.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/nix.logalpha.properties \$INSTALL_DIR/nix.logalpha.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/ncc/logalpha.properties \$INSTALL_DIR/ncc/logalpha.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/ncc/config-user.properties \$INSTALL_DIR/ncc/config-user.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/ncc/config.properties \$INSTALL_DIR/ncc/config.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/nis/logalpha.properties \$INSTALL_DIR/nis/logalpha.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/nis/db.properties \$INSTALL_DIR/nis/db.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/nis/config-user.properties \$INSTALL_DIR/nis/config-user.properties\"
\$sh_c \"ln -s \$CONFIG_DIR/nis/config.properties \$INSTALL_DIR/nis/config.properties\"

# setting permissions again
\$sh_c \"chown -R root:nem \$INSTALL_DIR\"
\$sh_c \"chown -R root:nis \$INSTALL_DIR/nis\"
\$sh_c \"chown -R root:ncc \$INSTALL_DIR/ncc\"
\$sh_c \"chmod -R g-w \$INSTALL_DIR\"
\$sh_c \"chmod -R o-rwx \$INSTALL_DIR\"
\$sh_c \"chmod g+rx \$INSTALL_DIR/*.sh\"

cd /tmp/neminstall 
rm -rf /tmp/neminstall
echo \"Finished upgrading NIS and NCC, start daemons with\"
echo \"sudo /etc/init.d/start start\"
echo \"sudo /etc/init.d/nis start\"
" > /tmp/neminstall/UpgradeNem
$sh_c "chmod +x  UpgradeNem"
$sh_c "mv UpgradeNem /usr/local/sbin/UpgradeNem"

$sh_c "chmod 0700 /etc/init.d/nis"
$sh_c "chmod 0700 /etc/init.d/ncc"


while true; do
	read -p "Do you want to run nis on startup? [yes/no]" yn
	case $yn in
		[Yy]* ) $sh_c "update-rc.d nis defaults"; $sh_c "update-rc.d nis enable"; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

while true; do
	read -p "Do you want to run ncc on startup? [yes/no]" yn
	case $yn in
		[Yy]* ) $sh_c "update-rc.d ncc defaults"; $sh_c "update-rc.d ncc enable"; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

rm -rf /etc/neminstall
echo "Added your bootName $bootname and a random bootkey $bootkey to $CONFIG_DIR/nis/config-user.properties"
echo "To start the NIS server, run: $sh_c /etc/init.d/nis start"
echo "To start the NCC server, run: $sh_c /etc/init.d/ncc start"

