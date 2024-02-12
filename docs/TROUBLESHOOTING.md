# Troubleshooting Guide

This guide provides solutions to common issues encountered when using DL4MicEverywhere.

## Docker Issues

### **Docker daemon fails to start**

- Ensure your OS meets the requirements for Docker Desktop. Docker requires Windows 10 Pro/Enterprise x64 or macOS 10.13+ .
- On Linux, ensure Docker engine is installed and the service is running. Check status with: `systemctl status docker`
- Confirm your user is in the `docker` group to avoid permission errors.

### **Cannot pull Docker images** 

- Verify internet connection and proxy settings. Docker needs access to Docker Hub.
- If authentication errors occur, re-enter Docker Hub credentials in Docker Desktop settings or `~/.docker/config.json`.
- For GitHub Package Registry images, ensure you are logged in with: `docker login docker.pkg.github.com`

### **Docker command not found**

- Ensure Docker CLI client is installed and in your PATH. 
- On Linux, you may need to add user to `docker` group. Log out and back in for changes to take effect.

### **Docker takes too long to start**

- Increase Docker resources in Preferences > Resources. At least 2 CPUs and 4GB memory recommended.
- On Linux, check other processes consuming resources. Docker may need more RAM/CPUs.

### **Docker desktop does not start or crashes after running DL4MicEverywhere on Mac**

- Ensure you are not using any Docker container in the terminal. Then, open a terminal and force quit Docker by typing: `pkill -SIGHUP -f /Applications/Docker.app 'docker serve'`

### **Docker cannot build image**
- Your docker client might be out of space. [Read here how to clear space](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/DOCKER_DESKTOP.md).


### **Docker Desktop - Windows Hypervisor is not present**

This issue happens on Windows computers because the virtualization is not enabled in you BIOS and usually comes with the following message and forcing Docker to stop or close.

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TROUBLESHOOTING/Windows_virt_docker.PNG" 
     alt="Docker virtualization"
     width="60%" 
     height="60%" />

This process requires you to restart your computer, enter the BIOS and enabling this option. For more detailed instructions, we recommend following the step described on the following videos [Enable Virtualization on Windows 10](https://www.youtube.com/watch?v=LQIyowZMiY8) or [Enable Virtualization on Windows 11](https://youtu.be/t8f-zw_wcWM?si=pG2FlhXMImwrWfg7).

## GPU Support

### **Notebooks fail with CUDA errors**

- Verify Nvidia drivers are properly installed for your GPU.
- Ensure `nvidia-docker` is installed and runtime is enabled in Docker.
- Consider updating Nvidia driver and CUDA to latest compatible versions.

### **Docker fails to detect GPU** 

- Check `nvidia-smi` works outside Docker. If not, reinstall Nvidia driver.
- Ensure no other processes (e.g. X server) are using GPU when starting Docker.

### **Out of memory on GPU**

- Lower batch size or model complexity to reduce VRAM usage.
- Consider using a GPU with more VRAM.
- Enable paging to swap some GPU memory to system RAM.

## Notebooks 

### **Notebooks fail to build**

- Check Docker build logs for errors. Debug or raise issue.
- Consider updating Docker engine and Nvidia driver to latest versions.

### **Terminal command of DL4MicEverywhere does not find the specified files**

- Ensure that all the paths are given with "quotation marks" and remove spaces in the file names. 
- Verify that the paths to the files are correct.

### **Mounted data and results folder in Jupyter lab are empty**

- Review the permissions to the folders you specified. If they are protected, DL4MicEverywhere will not be able to mount them. The first time launching DL4MicEverywhere, Docker will ask for permission to access the folder. Please, click on Yes.
- Security and privacy permissions to the folders in iOS (Mac) can be set up in Files and Folders as shown in the images: System Settings > Privacy & Security > Files and Folders > Docker > Activate the needed folders. (Note that all the content in DL4MicEverywhere is open-source, so you can check all the steps taken in the docker image build and also in the notebooks).
- <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/SECURITY_PRIVACY_MAC.png" 
     alt="Security and Permissions Mac"
     width="50%" 
     height="50%" /> <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/SECURITY_FOLDERS_MAC.png" 
     alt="Security and Permissions Mac"
     width="50%" 
     height="50%" />

### **Issues loading the data and errors with imagecodecs**

- Some .tiff files can be compressed and need `imagecodecs` python package to be installed. This package cannot be installed at the moment in iOS (Mac) systems. To fix this, the images need to be restored without compression.
  For this, you can either open and restore them without compression using `tifffile` in Python or you can use Fiji/ImageJ. Here is a quick ImageJ macro code to do it automatically:
  ```
  //-------------------------------------------------------------------------
  //  PATH: the path containing a folder with the images you want to open and save again as tif files.
  //  input_folder: the name of the folder containing the images. If it has a different name, please change it.
  //  new_folder_seg: the name of the new folder created to save the images again.
  //-------------------------------------------------------------------------

  PATH = "/Users/esti/Documents/DL4MicEverywhere/data/";
  input_folder = "images/";
  new_folder_seg = "uncompressed_images/";
  
  files = getFileList(PATH + input_folder);
  print(files.length+" images in the directory " + PATH);
  
  if (!File.exists(PATH + new_folder_seg)){
    	File.makeDirectory(PATH + new_folder_seg);
    	if (!File.exists(PATH + new_folder_seg)){
    		exit("Unable to create a directory for masks. Check User permissions.");
    	}
    }
  // Process each image with the trained model and save the results.
  for (i=0; i<files.length; i++) {
  	// avoid any subfolder
  	if (endsWith(files[i], ".tif")){
  		
  		// store the name of the image to save the results
  		image_name = File.getNameWithoutExtension(PATH + input_folder + files[i]);
  
  		// open the image
  		open(PATH + input_folder + files[i]);		
  		
  		// save
  		selectWindow("Result of " + files[i]);
  		saveAs("Tiff", PATH + new_folder_seg+image_name+".tif");
  		run("Close All");
  	}
  }
  ``` 

### **Notebooks run slow** 

- Increase allocated resources for Docker engine (CPUs/RAM).
- Lower model and data complexity. Simplify notebooks.
- Consider using a machine with more powerful CPU/GPU resources.

### **Notebooks crash/fail**

- Check notebook logs for errors and debug. 
- Raise issue with logs and steps to reproduce problem.

### **Models produce poor results**

- Ensure training data is sufficient and correctly formatted.
- Try tuning model hyperparameters and architecture.
- Consider using a more suitable model or training scheme.
  
## Launchers

### **`MacOs_launher` cannot be oppened**

MacOS computers will notify you that the file you want to launch cannot verified if it is free from malware and it will pop you the following message:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TROUBLESHOOTING/macos_cannot_open.png" 
     alt="Cannot open"
     width="30%" 
     height="30%" />

In that case, instead of double-clicking the file you will need to tight click it and chose the `Open` option as in the following image:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TROUBLESHOOTING/macos_right_click.png" 
     alt="Right click"
     width="40%" 
     height="40%" />

This time you will get a different message, and by clicking `Open` you are allowing your to run by double click the launcher for future occasions. 
     
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TROUBLESHOOTING/macos_allows_open.png" 
     alt="Allow open"
     width="30%" 
     height="30%" />

### **`Windows_launher` cannot be oppened**

Windows computers will warn you that the file you want to launch is an unrecognized app and will pop you the following message:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TROUBLESHOOTING/Windows_cannot_open.png" 
     alt="Windows cannot open"
     width="30%" 
     height="30%" />
     
To allow the double click launching you just need to choose the ´More info´ option and after that click on ´Run anyway´ as in it can be seen bellow, allowing with this to run this file in future occasions.


<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TROUBLESHOOTING/Windows_allow_open.png" 
     alt="Windows allow"
     width="30%" 
     height="30%" />
     
## General

### **WsRegisterDistribution failed with error: 0x80370102**

This issue happens on Windows computers because the virtualization is not enabled in you BIOS and usually comes with the following message and forcing Docker to stop or close.

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TROUBLESHOOTING/Windows_virt_wsl.PNG" 
     alt="WSL virtualization"
     width="60%" 
     height="60%" />

This process requires you to restart your computer, enter the BIOS and enabling this option. For more detailed instructions, we recommend following the step described on the following videos [Enable Virtualization on Windows 10](https://www.youtube.com/watch?v=LQIyowZMiY8) or [Enable Virtualization on Windows 11](https://youtu.be/t8f-zw_wcWM?si=pG2FlhXMImwrWfg7).

---

Still encountering problems? Search GitHub issues or raise a new one with details to reproduce the problem. We'll do our best to help resolve it!
