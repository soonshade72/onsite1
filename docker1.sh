#!/bin/bash
read -p "Enter image name: " img_name
img_tag="latest"
read -p "Enter Context directory: " bdir
mkdir -p "$bdir"

read -p "Name the file you want to create: " fname
cat << 'EOF' > "$bdir/$fname"
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(b"Hello, World!")

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8000), Handler)
    print("Serving on port 8000")
    server.serve_forever()
EOF

read -p "Enter base image: " bi
read -p "Enter Startup Command: " sc

cat << EOF > "$bdir/Dockerfile"
FROM $bi
WORKDIR /$bdir
COPY $fname .
CMD ["$sc","$fname"]
EOF
aa="y"
echo "services:" > "$bdir/docker-compose.yml"
while [[ "$aa" == 'y' ]]; do
read -p "Enter service name: " sv
read -p "Enter Container name: " con
read -p "You want to map to host port: " hp
read -p "Enter container port: " cp
read -p "What type of network: " net
read -p "What driver: " drv
read -p "Enter the volume mount: " vm
read -p "Enter dependency : " dep  
read -p "Enter restart policy :" restart_policy
read -p "Build from this Dockerfile? (y/n): " use_build
if [[ "$use_build" == 'y' ]]; then
  image_line="    build: .\n    image: $img_name"
else
  read -p "Enter image to use (e.g. mysql:8.0): " ext_image
  image_line="    image: $ext_image"
fi
read -p "Enter environment variables (KEY=VALUE, comma separated, leave blank if none): " envvars

cat << EOF >> "$bdir/docker-compose.yml"
  $sv:
$(echo -e "$image_line")
    container_name: $con
    ports:
      - "$hp:$cp"
    networks:
      - $net
    volumes:
      - $vm
    restart: $restart_policy
    healthcheck:
      test: ["CMD","echo","ok"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

if [ -n "$envvars" ]; then
  echo "    environment:" >> "$bdir/docker-compose.yml"
  IFS=',' read -ra envarr <<< "$envvars"
  for kv in "${envarr[@]}"; do
    echo "      - $kv" >> "$bdir/docker-compose.yml"
  done
fi

if [ -n "$dep" ]; then 
cat << EOF >> "$bdir/docker-compose.yml"
    depends_on:
      - $dep
EOF
fi
read -p "Add another service?(y/n)" aa
done
cat << EOF >> "$bdir/docker-compose.yml"
networks:
  $net:
    driver: $drv
EOF

echo -e "\nDockerfile:"
cat "$bdir/Dockerfile"
echo -e "\nDocker compose file:"
cat "$bdir/docker-compose.yml"

read -p "Open files for editing? (y/n) " choice
editor="nano"
if [[ "$choice" == 'y' ]]; then 
	$editor "$bdir/Dockerfile"
	$editor "$bdir/docker-compose.yml"
fi
echo -e "\nMoving to context directory..."
cd "$bdir" || exit

echo "Deploying the stack..."
if docker compose up -d --build;then 
  echo -e "\nLogs:"
  docker compose logs -f
else 
  echo -e "\nBuild or deploy failed"
  docker compose logs --tail=50
  exit 1
fi