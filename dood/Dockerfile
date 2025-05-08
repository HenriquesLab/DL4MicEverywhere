# Use an image with Docker installed
FROM docker:20.10
USER root
RUN apk add --no-cache bash
# Install necessary packages
RUN apk --no-cache add fontconfig ttf-dejavu tcl tk

WORKDIR /dl4mic
COPY . /dl4mic
EXPOSE 8888
# Command to run your application
CMD ["bash", "-E", "launch.sh"]

