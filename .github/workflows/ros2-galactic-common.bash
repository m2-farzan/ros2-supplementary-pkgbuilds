#!/bin/bash

set -e
cd /ros2-supplementary-pkgbuilds/ros2-galactic-common
AUR_USER=ab
chown -R ${AUR_USER}:${AUR_USER} .

sudo pacman -Syyu --noconfirm --noprogressbar

# Temporary fix (https://github.com/m2-farzan/ros2-galactic-PKGBUILD/issues/9)
pacman -S wget python-pip python-pyqt5 --noconfirm --noprogressbar
pip3 install pyqt5==5.15.5

# Temporary fix (waiting for https://github.com/acxz/pkgbuilds/issues/161)
sudo -u ${AUR_USER} yay -S python-colcon-core --noconfirm --noprogressbar
pip3 install colcon-core==0.7.0

sudo -u ${AUR_USER} git config --global user.name "Test User"
sudo -u ${AUR_USER} git config --global user.email "test@example.com"
cat .SRCINFO | grep -oP "depends\ \=\ \K.+" | xargs sudo -u ${AUR_USER} yay -S --noconfirm --noprogressbar --needed

sudo -u ${AUR_USER} bash -c "source /opt/ros2/galactic/setup.bash; source /usr/share/gazebo/setup.bash; source /usr/share/gazebo-11/setup.bash; makepkg"
