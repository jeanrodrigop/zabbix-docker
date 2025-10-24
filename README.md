# Deploy Zabbix Server and Grafana with Docker

If necessary, open the following ports in the firewall:<br>
TCP: 8080, 10051, 10050      
UDP: 162

Configure DB credentials in .env file.
 
<hr>

## Deploying:
Clone this repo:
```bash
$ git clone https://github.com/jeanrodrigop/zabbix-docker.git
```
Enter the repo:
```bash
$ cd zabbix-docker
```
Change permission:
```bash
$ chmod +x install-script.sh
```
Execute the script:
```bash
$ ./install-script.sh
```
<hr>

Build by Jean Rodrigo
