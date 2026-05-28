Setup a Closed Lab Environment with 2 Raspberry Pi's

This is a classroom setting where a Raspberry Pi needs to be setup as Jupyter Notebooks server offline. 

Workflow For Setup

* 1 Rpi (PC-pi) while Online is prepared to act as an apt and pip repo.
* Script pcpi-prepare.sh is run which will crate ~/offline_assests child directories apt and pip. 
* PC-pi is taken offline and networked directly to IOT-pi via APIPA.
* Connect to IOT-pi via console and change ethernet to link-local using nmtui.
* Change network on PC-pi to link-local using desktop GUI.
* Copy iotpi-setup.sh script from PC-Pi to IOT-pi.
*From in the ~/offline_assests directory on PC-pi Start python3 -m http.server 8080 to host repos
* Through the console run iotpi-setup.sh script on IOT-pi. 
* This will install python3 packages and required pip modules and configure Jupyter Notebooks server offline on IOT-pi. 
