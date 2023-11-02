# Troubleshooting Guide

This guide contains solutions to common problems when using DL4MicEverywhere.

## Docker Issues

**Docker daemon fails to start**

- Check that your OS meets the requirements for Docker Desktop. Docker requires Windows 10 Pro/Enterprise x64 or macOS 10.13+ 
- On Linux, make sure Docker engine is installed and the service is running. Check status with `systemctl status docker`
- Verify your user is in the `docker` group to avoid permission errors.

**Cannot pull Docker images** 

- Check internet connection and proxy settings. Docker needs access to Docker Hub.
- If authentication errors, re-enter Docker Hub credentials in Docker Desktop settings or `~/.docker/config.json`.
- For GitHub Package Registry images, make sure you are logged in with `docker login docker.pkg.github.com`

**Docker command not found**

- Make sure Docker CLI client is installed and in your PATH. 
- On Linux, you may need to add user to `docker` group. Log out and back in for changes to take effect.

**Docker takes too long to start**

- Increase Docker resources in Preferences > Resources. At least 2 CPUs and 4GB memory recommended.
- On Linux, check other processes consuming resources. Docker may need more RAM/CPUs.

**Docker desktop does not start or crushed after running DL4MicEverywhere in Mac**

- Please, make sure you are not using any Docker container in the terminal. Then, open a terminal and force quit Docker by typing `pkill -SIGHUP -f /Applications/Docker.app 'docker serve'`


## GPU Support

**Notebooks fail with CUDA errors**

- Verify Nvidia drivers are properly installed for your GPU.
- Make sure `nvidia-docker` is installed and runtime is enabled in Docker.
- Try updating Nvidia driver and CUDA to latest compatible versions.

**Docker fails to detect GPU** 

- Check `nvidia-smi` works outside Docker. If not, reinstall Nvidia driver.
- Make sure no other processes (e.g. X server) are using GPU when starting Docker.

**Out of memory on GPU**

- Lower batch size or model complexity to reduce VRAM usage.
- Use a GPU with more VRAM.
- Enable paging to swap some GPU memory to system RAM.

## Notebooks 

**Notebooks fail to build**

- Check Docker build logs for errors. Debug or raise issue.
- Try updating Docker engine and Nvidia driver to latest versions.

**Terminal command of DL4MicEverywhere does not find the specified files**

- Please, make sure that all the paths are given with "quotation marks" and remove spaces in the file names. 
- Check that the paths to the files are correct.

**Mounted data and results folder in Jupyter lab are empty**

- Review the permission to the folders you specified. If they are protected, DL4MicEverywhere will not be able to mount them. The first time launching DL4MicEverywhere, Docker will ask for permission to access the folder. Please, click on Yes.
- Security and privacy permission to the folders in iOS (Mac) can be set up in Files and Folders as shown in the images: System Settings > Privacy & Security > Files and Folders > Docker > Activate the needed folders. (Note that all the content in DL4MicEverywhere is open-source, so you can check all the steps taken in the docker image build and also in the notebooks).
- <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/SECURITY_PRIVACY_MAC.png" 
     alt="Security and Permissions Mac"
     width="50%" 
     height="50%" /> <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/SECURITY_FOLDERS_MAC.png" 
     alt="Security and Permissions Mac"
     width="50%" 
     height="50%" />

**Issues loading the data and errors with imagecodecs**

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

**Notebooks run slow** 

- Increase allocated resources for Docker engine (CPUs/RAM).
- Lower model and data complexity. Simplify notebooks.
- Use a machine with more powerful CPU/GPU resources.

**Notebooks crash/fail**

- Check notebook logs for errors and debug. 
- Raise issue with logs and steps to reproduce problem.

**Models produce poor results**

- Ensure training data is sufficient and correctly formatted.
- Try tuning model hyperparameters and architecture.
- Use more suitable model or training scheme.
  
## General

Still having problems? Search GitHub issues or raise a new one with details to reproduce the problem. We'll do our best to help resolve it!