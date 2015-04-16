#Nem-Installers#

This repository provides scripts for easy install of Nem Infrastructure Server (nis) and Nem Community Client (ncc) for running a Node.

**install_nem.sh**  
Downloads the latest ncc-nis package from the [offical repository](http://bob.nem.ninja/), verifies the authenticity and installs ncc and nis.

**ubuntu_install_nem_tools.sh**  
Will install Oracle-Java-8 if needed, as well as other software. It also will help to create a swap partition and setup a basic firewall for the server

This script is currently tested against debian and ubuntu linux distributions. It might work on other distributions as well, but there is no guarantee. Feel free to help create scripts for other distributions


### Overview
- [Installation](#installation)
  + [Requirements](#requirements)
  + [Instructions](#instructions)
  + [Configuration](#configuration)  
- [FAQ](#faq)
  + [Install Oracle Java 8](#how-can-i-install-oracle-java-8)  
  [Ubuntu](#ubuntu)  
  [Debian](#debian)  
- [Changelog](#changelog)
- [Contributions](#contributions)
- [License & Disclaimer](#licence-and-disclaimer)  
  

### Installation
#### Requirements  
The requirements for running nis and nem is Oracle Java 8.  
For help installing Oracle Java 8 [please see here](#how-can-i-install-oracle-java-8) 
  
#### Instructions  

Fetch the latest version of the scripts from the github repository and uncompress
```
wget https://github.com/jadedjack/Nem-Installers/archive/master.zip
unzip master.zip
```
  
Install ncc/nis with this command and follow the instructions
```
./install_nem.sh
```
  
For installing tools and setting up a basic firewall just run
```
./ubuntu_install_nem_tools.sh
```  
  
You can start nis or ncc by typing
```
sudo /etc/init.d/nis start
sudo /etc/init.d/ncc start
```  

Stopping nis or ncc is done via
```
sudo /etc/init.d/nis stop
sudo /etc/init.d/ncc stop
```

##### Configuration  
Configuration files are located at `/etc/nem` and the subfolders `/etc/nem/nis`, `/etc/nem/ncc`, `/etc/nem/mon`
Default configuration values are stored in `config.properties` file and are overwritten by `config-user.properties`

For more information on NIS/NCC configuration options visit the official nem documentation


### FAQ

#### How can I install Oracle Java 8?  

###### Ubuntu  
For ubuntu you need to add the webupd8team/java ppa repository and then run apt-get for installation  

```
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get update
sudo apt-get install oracle-java8-installer -y
```
For more Information visit [wepup8 Java 8 Ubuntu instructions](http://www.webupd8.org/2012/09/install-oracle-java-8-in-ubuntu-via-ppa.html)  

###### Debian
For debian you need add the webupd8team/java ppa repository and then run apt-get for installation 

```
su -
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
apt-get update
apt-get install oracle-java8-installer
exit
```
For more Information visit [wepup8 Java 8 Debian instructions](http://www.webupd8.org/2014/03/how-to-install-oracle-java-8-in-debian.html)

#### How can I updated my NEM installation  
Simply by using the command `sudo UpgradeNem`. The script will automatically check for the latest version and update your nem installation if necessary  
  
  
#### How can I disable/enable nis/nss from starting automatically?
###### Disbale  
**nis**
```
sudo update-rc.d nis remove
```  
  
**ncc**
```
sudo update-rc.d ncc remove
```

###### Enable  
**nis**
```
sudo update-rc.d nis defaults
sudo update-rc.d nis enable
```

**ncc**
```
sudo update-rc.d ncc defaults
sudo update-rc.d ncc enable
```
  
#### How can I change the amount of RAM used for NIS?
To change the RAM size that is allocated, edit `/etc/init.d/nis`
Change the line `export MAXRAM=1G` to your desired value (i.e 768M) 

----
For more information or discussion please visit [this thread on the OurNem Forum](https://forum.ournem.com/vps-nodes/how-to-easily-configure-and-install-nem-on-an-amazon-ec2-vps/msg14400/#msg14400)

#### Changelog
- 2014.04.15  
   - version bump to 0.1.1
   - fixed permission for /etc/nem/keys
   - updated README file
   - adapted for 0.6.28 client naming conventions
- 2014.04.14  
   - automatically fetch latest Version  
   - config files are now at /etc/nem  
   - nem default installation directory is now /opt/nem  
   - the directory for data is now located at /var/lib/nem  
   - sanity checks for required installation dependencies  

#### Contributions
We would to thank the following people for creating (parts) of this script
- Jadejack (initial version)
- patrickjahns (further updates)

The upstart scripts have been written by [riegel](https://forum.ournem.com/technical-discussion/secure-nis-and-ncc-setup-on-linux/) and modified for this release

Please feel free to contribute to this repository.

#### Licence and Disclaimer
The scripts are Licensed under 3-clause BSD. 

**Disclaimer**  
This script is community maintained and any upgrade/update of the nem Software might brake the scripts

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.


