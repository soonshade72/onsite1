#! bin/bash
read -p "Enter image name:" img_name
img_tag="latest"
read -p "Enter Context directory:" bdir
mkdir -p "$bdir"
read -p "Name the file you want to create:" fname
echo << 'EOF' > "$bdir/fname"
print("Hello,World!")
EOF
read -p "Enter base image:" bi
read -p "Enter Startup Command :" sc
cat << EOF > "$bdir/DockerFile.server"
From $bi
WORKDIR /$bdir
COPY ser.py
CMD [$sc]
EOF
docker build -t "${img_name}:${img_tag}" "$bdir"
read -p "Enter service name :" sv
read -p "Enter Container name:" con
read -p "You want to map to host port :" hp
read -p " Enter conatiner port :" cp
read -p "What type of network :" net
read -p "what driver : "drv
read -p "Enter the volume mount:" vm
read -p "Enter dependency:"dep  
cat << EOF >docker-compose.yml 
services :
	$sv:
	image:$img_name
	container_name:$con
	ports:
	 - "$hp:$cp"
	 networks:
	 - $net
	 volumes:
	 - $vm
	 depends_on:
	 - $dep:
EOF


	
