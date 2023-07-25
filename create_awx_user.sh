echo "AWX user password: "
read AWX_PASSWORD

sudo useradd awx
sudo passwd awx > /dev/null << EOF
$AWX_PASSWORD
$AWX_PASSWORD
EOF
sudo usermod -aG wheel awx
