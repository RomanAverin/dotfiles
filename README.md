# Configuration Fedora 36/37
## Drivers

* Install Nvidia drivers + CUDA

```
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora35/x86_64/cuda-fedora35.repo
sudo dnf clean all
sudo dnf -y module install nvidia-driver:latest-dkms
sudo dnf -y install cuda
```

* Logitech drivers and config

```
sudo dnf install logiops
sudo cp config/logid.cfg /etc/
sudo chown root:root /etc/logid.cfg
sudo systemctl enable logid.service
sudo systemctl start logid.service
```
## Environment

* Install zsh + ohmyzsh
```
sudo dnf install git zsh vim
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
