# Connect to remote workstations via SSH

You can use the GUI with remote workstations when an SSH connection is established. 

**iOS / Mac**
If you are using an iOS system to connect via SSH, you need to install [Xquartz](https://www.xquartz.org/). You can easily do this using the following command in the terminal:
```
brew install --cask xquartz
```
You need to restart the system after the installation. 

**Launching the remote SSH connection**

Try one of these: 
```
ssh -Y username@XXX.XX.XX.XXX
```
or 
```
ssh -L -Y usernam@XXX.XX.XX.XXX
```
or
```
ssh -X username@XXX.XX.XX.XXX
```
or 
```
ssh -L -X username@XXX.XX.XX.XXX
```

The `-Y` option in the `ssh` command enables trusted X11 forwarding. This means that the remote X11 applications have permissions to connect to the local X11 display. It is a secure way to run X11 applications on a remote machine and have them displayed on a local machine. The `-Y` option is preferred over the `-X` option, for security reasons.


The `-L` option in the `ssh` command is used to set up local port forwarding. It allows you to create a secure tunnel from a local machine to a destination machine through the SSH server. This can be useful for accessing services on a remote machine securely or for bypassing firewall restrictions.
When using the `-L` option, you specify the local address and port, the remote address, and the remote port to which the traffic will be forwarded. For example, the following command sets up local port forwarding: `ssh -L 8080:localhost:80 user@remote`. This command forwards all traffic sent to port `8080` on the local machine to port `80` on the remote machine.
Local port forwarding can be used to secure traffic and access remote services securely. It is commonly used in scenarios where direct access to a service is restricted or when encryption and security are required for the communication.

**Run DL4MicEverywhere**
```
cd DL4MicEverywhere
sudo -E bash Linux_launch.sh
```
**Launch Jupyter lab with the remote port**
After the Docker image is built and Jupyter lab is launched remotely, you need to connect via SSH to the port assigned to Jupyter. To do this, check the new window for the port. For example, in the image below, it is `8888`
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/JUPYTER_TOKEN_TERMINAL.png" 
     alt="Terminal after running Jupyter Lab"
     width="60%" 
     height="60%" />

To establish the connection, open a new window in the Terminal and type:
```
ssh -L 8888:localhost:8888 username@XXX.XX.XX.XXX
```
Copy the path given by the terminal into a browser (the one highlighted in the screenshot above).
