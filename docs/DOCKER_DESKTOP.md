# Docker Desktop Overview

Docker Desktop is a tool for managing Docker containers and images. It provides a visual interface for monitoring the Docker images installed on your computer and the containers currently running.

## Cleaning Docker Containers and Images

Docker images typically occupy between 3 - 5 GB of memory. Therefore, it's advisable to periodically review and remove any unnecessary images. To do this, first check if any container is using the image. If so, stop and remove it by clicking on the bin symbol. 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DOCKER_DESKTOP_CONTAINER.png" 
     alt="Docker desktop container"
     width="50%" 
     height="50%" />

Next, navigate to Images and remove any images that are no longer needed.

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DOCKER_DESKTOP_IMAGE.png" 
     alt="Docker desktop images"
     width="50%" 
     height="50%" />

To display all the container images currently occupying space on your computer, use:

`sudo docker images`

To remove all unused images, use:

`docker image prune -a`

To remove all unused containers, networks, and images, use:

`docker system prune -a`


## Managing Docker

You can pause, restart, or close Docker by clicking on the Docker shortcut symbol: 
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/STOP_DOCKER.png" 
     alt="Docker desktop images"
     width="50%" 
     height="50%" />
