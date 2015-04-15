#Nem-Installers#

Here are two scripts that will install nem and its dependencies on Ubuntu

Something may break with nis and ncc updates. But i will attempt to keep the scripts current.
No guarantees provided.

The first script, Install-nem-dependencies.sh, will create a swap file if wanted, download java and some other useful software, and setup a basic firewall.

The second script, Safe-nem-install.sh, will download the nis-ncc server directly from  http://bob.nem.ninja/ and check it with Gimre's published public key to be sure it is authentic.


Changes
April 14 2014 - Safe-nem-install.sh script will automatically get latest version and download , it also installs the client to a more standard linux installation 

Thanks to mrjp and rigel :-)


Get both files by entering the command

    wget https://github.com/jadedjack/Nem-Installers/archive/master.zip

Then uncompress them

    unzip master.zip

Then run the Install-nem-dependencies.sh script, follow the prompts when software is loaded.

    ./Install-nem-dependencies.sh

Then run Safe-nem-install.sh script.

    ./Safe-nem-install.sh

You can choose to have NIS started automatically or,

You can start NIS with

    /etc/init.d/nis start

You can start NCC with

    /etc/init.d/ncc start

Stop NIS with

    /etc/init.d/nis stop

Stop NCC with

    /etc/init.d/ncc stop

Upgrade NIS NCC with latest version, for example

    UpgradeNem

The configuration files are saved to /etc/nem
If you want to change something in the nis configuration for example edit it with your favorite text editor.

    sudo nano /etc/nem/nis/config-user.properties

For more questions go to

[https://forum.ournem.com/vps-nodes/how-to-easily-configure-and-install-nem-on-an-amazon-ec2-vps/msg14400/#msg14400](https://forum.ournem.com/vps-nodes/how-to-easily-configure-and-install-nem-on-an-amazon-ec2-vps/msg14400/#msg14400 "Ournem Forum")

Good Luck and have fun.
 :)
