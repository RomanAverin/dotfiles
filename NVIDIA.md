* Remove and blacklist Nouveau driver

[Link to guard](https://www.if-not-true-then-false.com/2015/fedora-nvidia-guide/)

```
sudo dnf remove xorg-x11-drv-nouveau
sudo echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf

```
* Module options

```
sudo cp config/nvidia.conf /etc/modprobe.d/
sudo chown root:root /etc/modprobe.d/nvidia.conf
```

* Add change boot options for kernel 

```
sudo vim /etc/default/grub
```
change for Wayland support:
`GRUB_CMDLINE_LINUX="rhgb quiet rd.driver.blacklist=nouveau nvidia-drm.modeset=1"`

* Rebuild grub config
```
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
``` 
* Reboot to runlevel 3
```
systemctl set-default multi-user.target
reboot
```

* Choose one of the methods
  * Install Nvidia drivers(Fusion Repo)
[Guard](https://rpmfusion.org/Howto/NVIDIA#CUDA)

  ```
  sudo dnf install akmod-nvidia
  sudo dnf install xorg-x11-drv-nvidia-cuda
  ```

  * Install Nvidia drivers + CUDA(Nvidia Repo)

  ```
  sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora36/x86_64/cuda-fedora36.repo
  sudo dnf clean all
  sudo dnf -y module install nvidia-driver:latest-dkms
  sudo dnf -y install cuda
  ```
* Return to runlevel 5
```
systemctl set-default graphical.target
```

* Install CUDA only

[https://rpmfusion.org/Howto/CUDA](https://rpmfusion.org/Howto/CUDA)

```
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora36/x86_64/cuda-fedora36.repo
sudo dnf clean all
sudo dnf module disable nvidia-driver
sudo dnf -y install cuda
```