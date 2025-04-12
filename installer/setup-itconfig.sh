docker exec -it deluge /bin/bash

mkdir -p /config/plugins

cd /config/plugins

wget https://github.com/ratanakvlun/deluge-ltconfig/releases/download/v2.0.0/ltConfig-2.0.0.egg

exit

docker restart deluge
