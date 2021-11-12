FROM ghcr.io/greyltc-org/archlinux-aur:yay
ARG AUR_USER=ab

RUN pacman -Syyu --noconfirm --noprogressbar

RUN sudo -u $AUR_USER git config --global user.name "Test User"
RUN sudo -u $AUR_USER git config --global user.email "test@example.com"

# INSTALL ROS2
USER $AUR_USER
WORKDIR /ros2-pkg
RUN git clone https://github.com/m2-farzan/ros2-galactic-PKGBUILD .

USER root
RUN cat .SRCINFO | grep -oP "depends\ \=\ \K.+" | xargs sudo -u $AUR_USER yay -S --noconfirm --noprogressbar --needed

COPY ros2-bin /ros2-bin
RUN pacman -U $(find /ros2-bin -type f)

# INSTALL ROS2-COMMON
USER $AUR_USER
WORKDIR /ros2-common-pkg
RUN mkdir src artifact

USER root
RUN cat .SRCINFO | grep -oP "depends\ \=\ \K.+" | xargs sudo -u $AUR_USER yay -S --noconfirm --noprogressbar --needed

CMD [ "bash", "-c", "chown -R ab:ab /ros2-common-pkg && sudo -u ab bash -c 'source /opt/ros2/galactic/setup.bash && env PKGDEST=/ros2-common-pkg/artifact makepkg'" ]
