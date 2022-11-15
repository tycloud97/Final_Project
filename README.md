# Admin PC preparation

- Ensure you have Ansible, Terraform, an SSH client, kubectl, kubens and helm installed
- All done on Kali GNU/Linux Rolling
- Generate ssh key pair:

```bash
ssh-keygen -t rsa -b 4096
```

# Installing Proxmox VE

## Installing Debian 11 Bullseye

- Download the latest Debian 11 stable release ISO
- Use **Balena Etcher** to flash ISO to USB
- Reboot, change boot order in BIOS and reboot again
- Proceed with installation
- Edit var files for Terraform, Ansible and Kubernetes and add/edit:
	- users
	- passwords
	- ssh keys
	- ip addresses
	- network interfaces
	- other network settings (gateway, dns, subnet, namespaces, ...)
- Enable root ssh login
- Add PVE instance to Ansible inventory
- Run the PVE installation playbook:

```bash
ansible-playbook -i ansible/inventories/inventory.ini --ask-pass --ask-vault-pass ansible/playbooks/pve.yml
```

- Add users in Web GUI
- Add API token for Terraform and add it to the environment variables

# VM creation and configuration

- Run VM template playbook:

```bash
ansible-playbook -i ansible/inventories/inventory.ini --ask-vault-pass ansible/playbooks/vm_template.yml
```

- Apply the Terraform module to create base VMs

```bash
terraform plan
```

```bash
terraform apply
```

- Run VM configuration playbook to configure all of the VMs

```bash
ansible-playbook -i ansible/inventories/inventory.ini --ask-vault-pass ansible/playbooks/vm_conf.yml
```

# Kubernetes configuration

- Create `oc` and `cert-manager` namespaces:

```bash
kubectl create ns oc
```

```bash
kubectl create ns cert-manager
```

- Create NFS storage class

```bash
kubectl apply -f kubernetes/nfs/rbac.yml
```

```
kubectl apply -f kubernetes/nfs
```

- Install the cert-manager helm chart:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml
```

```bash
helm repo add jetstack https://charts.jetstack.io
```

```bash
helm install cert-manager --namespace cert-manager --version v1.9.1 jetstack/cert-manager
```

- Create Letsencrypt cluster issuer:

```bash
kubectl apply -f kubernetes/letsencrypt.yml
```

- Change current namespace to "oc":

```bash
kubens oc
```

- Deploy MySQL Kubernetes operator:

```bash
kubectl apply -f kubernetes/mysql-operator/deploy-crds.yml
```

```bash
kubectl apply -f kubernetes/mysql-operator/deployment.yml
```

- Deploy InnoDB cluster:

```bash
helm install mysql mysql-operator/mysql-innodbcluster \
    --set datadirVolumeClaimTemplate.storageClassName="nfs-sc" \
    --set datadirVolumeClaimTemplate.accessModes="ReadWriteMany" \
    --set datadirVolumeClaimTemplate.resources.requests.storage="5Gi" \
    --set credentials.root.user="root" \
    --set credentials.root.password=$MYSQL_PASSWORD \
    --set credentials.root.host="%" \
    --set serverInstances=3 \
    --set routerInstances=3 \
    --set tls.useSelfSigned=true \
    --set serverVersion="8.0.30" \
    --namespace oc
```

- Wait for the InnoDB cluster to be ready
- Deploy OC:

```bash
kubectl apply -f kubernetes/oc
```
- Get Wireguard config from the endpoint server for remote administration

# Literature (incomplete)
- https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_11_Bullseye
- https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/
- https://www.balena.io/etcher/
- https://cdimage.debian.org/cdimage/cloud/
- https://docs.ansible.com/ansible_community.html
- https://www.terraform.io/downloads
- https://www.terraform.io/docs
- https://registry.terraform.io/providers/Telmate/proxmox/latest/docs
- https://github.com/linuxserver/docker-wireguard
- https://docs.haproxy.org/2.6/configuration.html
- https://www.domstamand.com/adding-haproxy-as-load-balancer-to-the-kubernetes-cluster/
- https://hub.docker.com/_/haproxy
- https://cloud.google.com/docs/terraform/best-practices-for-terraform#module-structure
- https://pve.proxmox.com/wiki/Firewall
- https://www.youtube.com/watch?v=X48VuDVv0do&t=11105s
- https://k3s.io/
- https://medium.com/tailwinds-navigator/kubernetes-tip-how-to-make-kubernetes-react-faster-when-nodes-fail-1e248e184890
- https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
- https://dev.mysql.com/doc/mysql-operator/en/mysql-operator-introduction.html
- https://artifacthub.io/packages/helm/cert-manager/cert-manager
- https://dev.mysql.com/doc/mysql-operator/en/mysql-operator-introduction.html