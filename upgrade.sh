# Download the latest binary
wget https://github.com/QuilibriumNetwork/ceremonyclient/releases/download/v1.4.17/node-1.4.17-linux-amd64.bin

# backup the node binary 
mv /root/go/bin/node /root/go/bin/node1.4.16

# Move the latest node
mv node-1.4.17-linux-amd64.bin /root/go/bin/node

# change the permissions
chmod +x /root/go/bin/node

# stop the ceremonyclient
service ceremonylcient stop

# download the source
wget https://github.com/QuilibriumNetwork/ceremonyclient/archive/refs/tags/v1.4.17.zip

#install unzip
sudo apt install unzip

#unzip the folder
unzip v1.4.17.zip

# Remove the old Qclient
rm /root/go/bin/qclient

#build
cd ~/ceremonyclient-1.4.17/client
GOEXPERIMENT=arenas go build -o /root/go/bin/qclient main.go

#restart the service
service ceremonyclient start

#delay
sleep 20

# stop the ceremonyclient
service ceremonyclient stop

#restart the service
service ceremonyclient start

# Show node service status
systemctl status ceremonyclient --no-pager
