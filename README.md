# Configuration Fedora 35/36/37
## Drivers

* Install Nvidia drivers + CUDA

```
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora35/x86_64/cuda-fedora35.repo
sudo dnf clean all
sudo dnf -y module install nvidia-driver:latest-dkms
sudo dnf -y install cuda
```
* Install CUDA only

[https://rpmfusion.org/Howto/CUDA](https://rpmfusion.org/Howto/CUDA)

```
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora35/x86_64/cuda-fedora35.repo
sudo dnf clean all
sudo dnf module disable nvidia-driver
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
cp config/.zshrc ~
```
* Shell aliases
```
alias upall='sudo dnf update --refresh -y && flatpak update -y'
```
* DNF aliases
#### .zshrc

```
alias dnf.upgrade="sudo dnf upgrade --assumeyes && flatpak update --assumeyes && flatpak remove --unused"
alias dnf.install="sudo dnf install"
alias dnf.remove="sudo dnf remove"
alias dnf.search="sudo dnf --cacheonly search"
alias dnf.provides="sudo dnf --cacheonly provides"
alias dnf.list_installed="sudo dnf --cacheonly list installed"
alias dnf.repolist="sudo dnf --cacheonly repolist"
alias dnf.list_package_files="sudo dnf --cacheonly repoquery --list"
alias dnf.history_list="sudo dnf --cacheonly history list --reverse"
alias dnf.history_info="sudo dnf --cacheonly history info"
alias dnf.requires="sudo dnf --cacheonly repoquery --requires --resolve"
alias dnf.info="sudo dnf --cacheonly info"
alias dnf.whatrequires="sudo dnf repoquery --installed --whatrequires"
alias dnf.repo_disable="sudo dnf config-manager --set-disabled"
```
#### /etc/sudoers.d/40-nopasswd
```
# dnf.upgrade
%wheel ALL = NOPASSWD: /usr/bin/dnf upgrade --assumeyes
# dnf.search
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly search *
# dnf.provides
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly provides *
# dnf.list_installed
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly list installed
# dnf.repolist
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repolist
# dnf.list_package_files
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repoquery --list
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repoquery --list *
# dnf.history_list
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly history list --reverse
# dnf.history_info
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly history info
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly history info *
# dnf.requires
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repoquery --requires --resolve
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repoquery --requires --resolve *
# dnf.info
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly info
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly info *
# dnf.whatrequires
%wheel ALL = NOPASSWD: /usr/bin/dnf repoquery --installed --whatrequires *
``` 