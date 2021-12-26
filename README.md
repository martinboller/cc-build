# CyberChef Installation script

### Bash script automating the installation of the latest version of GCHQ's CyberChef on Debian 10 or 11

The final build of CyberChef will be located in 
- /var/www/CyberChef

### Design principles:
  - Create a production build of CyberChef on a (disposable) system with Vagrant. This system has the hostname *charpentier*.
  - Copy the production build to the virtual host if using Vagrant.
  - Create another Virtual Server using Vagrant using that build with NGINX. This has the hostname *cyberchef*.
  - Alternatively copy the build to another Web Server.

<b>Note:</b> CyberChef will only build on Node 10, but appear to run nicely on newer version. Therefore the actual web-server will be running the Package in the Debian repositories.

----

## Latest changes

### 2021-12-26 - First commit
- Two virtual machines created. Remove the first after successful installation of both servers.
- \# vagrant destroy charpentier
  
---
The simplified installation-flow is depicted below.


<img src="./Images/BuildCC.png" alt="Build flow"/>


---

## CyberChef - The Cyber Swiss Army Knife
From "about" in the web app:

*CyberChef is a simple, intuitive web app for analysing and decoding data without having to deal with complex tools or programming languages. CyberChef encourages both technical and non-technical people to explore data formats, encryption and compression.*


<img src="./Images/CyberChef.png" alt="CyberChef Web App"/>


To learn more about CyberChef, I recommmend these resources:
CyberChe Wiki: https://github.com/gchq/CyberChef/wiki
Training: https://www.networkdefense.co/courses/cyberchef/
