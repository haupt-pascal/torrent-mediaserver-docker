sudo bash -c 'echo "options i915 enable_guc=2" > /etc/modprobe.d/i915.conf'
sudo update-initramfs -u
sudo apt install intel-media-va-driver vainfo intel-gpu-tools
sudo bash -c 'echo "{
  \"storage-driver\": \"overlay2\",
  \"log-driver\": \"json-file\",
  \"log-opts\": {
    \"max-size\": \"10m\",
    \"max-file\": \"3\"
  }
}" > /etc/docker/daemon.json'
sudo systemctl restart docker
sudo apt clean -y
sudo apt autoremove -y
sudo apt install cpufrequtils -y
sudo systemctl disable ondemand
sudo bash -c 'echo "GOVERNOR=performance" > /etc/default/cpufrequtils'
sudo systemctl restart cpufrequtils
docker system prune -a --volumes