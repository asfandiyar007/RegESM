

**
## RegESM Working links  #[2021]
** 

|So i wanted to work on RegESM and i could not find any good notebook with working links so i updated all the links and its working now. Kindly follow the below steps to get started|  |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--|
|                                                                                                                                                                                    |  |

**step (1):** Type below commands in terminal and we will call this terminal in this Notebook

**---------------**Install these before anything**--------------**

     
    sudo apt update
    sudo apt-get install m4
    sudo apt install build-essential
    sudo apt-get install manpages-dev
    sudo apt-get install gfortran

----------------- **Installation Method Step by Step** ----------
**Step (2):** Clone the official Repo of RegESM 

> We will type this in terminal

    git clone https://github.com/uturuncoglu/RegESM.git
    cd $PROGS
    cd RegESM
    sudo chmod +x install-deps.sh

**Step(3):** Go to *RegESM folder*
 ![RegESM folder](https://github.com/asfandiyar007/RegESM/blob/master/Images/Screenshot%20from%202021-11-07%2023-38-51.png)![Changing Username](https://github.com/asfandiyar007/RegESM/blob/master/Images/Screenshot%20from%202021-11-07%2023-39-34.png)

> If you don't know your username type this in terminal `whoami`

**Step (4):** Open another terminal and type below 

    sudo -i 

> It will ask for password so enter the password

    cd /home/username/RegESM 

 - [ ] **change the /username to what your computer username is in above code**
 

> For example: mine was `cd /home/rippler/RegESM`

**Step (6):** Run the Script by typing below

    sudo ./install-deps.sh  

--------------------------------------------------------------
 that's it all done now wait and see if you get any errors  
-------------------------------------------------------------



