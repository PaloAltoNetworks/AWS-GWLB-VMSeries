This is a auto-scaling template for paloalto firewalls on aws environment for supporting Load Balacer Gateway (GWLB).
This "firewall" folder contains:
1. Template to deploy on the aws gui [firewall-new-vpc-v3.0.template]
2. Lambda functions for the solution [ init.py, fw_init.py, sched_evt1.py, sched_evt2.py, lib, dnslib, sha.py]
3. init-cfg.txt with panorama bootstrapping information

Here are the requirements for successful deployment :

Panorama:
1. We need panorama to :
	i. bootstrap the firewalls 
	ii. handle config changes and push the same to the firewalls in specific DG
	iii. delicense the firewalls

For panorama to perform the above functions we have to have the following conditions satisfied:

1. Panorama should allow AWS public IPs. Firewall will try to access Panorama from NAT GW external IP created by template. 
2. As a good practice keep a set of DG and templatestack for each firewall stack .
3. Configure the template on panorama with the following details and associate with corresponding templatestack: 
Template config:
A. Configure Interfaces (ethernet1/1 on slot 1). Set up interfaces as type Layer3 with DHCP.
   Note: enable default gateway on the trust interface.
B. Create one zone (trust)
C. Create a Virtual Router [name has to follow format : VR-tempstackname]. Enable ECMP on the Virtual Router.
D. Under Device->Services, configure primary DNS to 169.254.169.253 (the AWS DNS address).
E. Under Device->Services, configure FQDN refresh time of 60 seconds.
F. Create administrator Username/password as pandemo/demopassword (creating an Admin user on the template requires
that the templatestack and template first be defined and committed to Panorama).  A different
firewall admin user may be created, but that will require the firewall API key to be
specified for CFT deployment (the template, by default, specifies an API key associated
with the pandemo/demopassword user).		
DeviceGroup config:
A. Under Security Pre-Rules: Create an 'allow_all' rule allowing all traffic.  Select 'any' for Source, User,
   Destination, and Application.  Under 'Service/URL Category,' select 'any' (do not use 'application-default').

4. Add the delicense key of the firewall on the panorama. [Can be seen using :xxxx@Panorama> request license api-key show  on the panorama cli]
