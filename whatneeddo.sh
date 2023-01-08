#!/bin/sh
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/enforcing/disabled/' /etc/selinux/config
swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
yum -y install ntpdate
ntpdate time.windows.com
yum -y install yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum repolist
yum -y install docker-ce
mkdir /etc/docker
echo "Begin set docker mirror"

if [ $# -lt 1 ]; then
	filename="/etc/docker/daemon.json"
else
	filename=$1
fi
cat>$filename<<EOF
{
    "registry-mirrors":[
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://registry.docker-cn.com"
    ],
    "exec-opts":["native.cgroupdriver=systemd"]
}
EOF
systemctl start docker 
systemctl enable docker
docker info
echo "Begin set kubenetes"
if [ $# -lt 1 ]; then
	filename="/etc/yum.repos.d/kubernetes.repo"
else
	filename=$1
fi
cat>$filename<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum makecache
yum repolist
yum install -y kubelet-1.23.0 kubeadm-1.23.0 kubectl-1.23.0
systemctl enable kubelet