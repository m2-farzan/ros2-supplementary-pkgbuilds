FROM ghcr.io/greyltc-org/archlinux-aur:yay
ARG AUR_USER=ab

RUN pacman -Syyu --noconfirm --noprogressbar

RUN sudo -u $AUR_USER git config --global user.name "Test User"
RUN sudo -u $AUR_USER git config --global user.email "test@example.com"

# Share yay cache
USER $AUR_USER
COPY --chown=$AUR_USER yaycache /var/ab/.cache/yay

# INSTALL ROS2-COMMON
USER $AUR_USER
WORKDIR /ros2-common-pkg
COPY --chown=$AUR_USER ros2-galactic-common .
RUN mkdir src artifact

USER root
RUN cat .SRCINFO | grep -oP "depends\ \=\ \K.+" | xargs sudo -u $AUR_USER yay -S --noconfirm --noprogressbar --needed

CMD [ "bash", "-c", "pacman -Ql gazebo && chown -R ab:ab /ros2-common-pkg && sudo -u ab bash -c 'source /opt/ros2/galactic/setup.bash && source /usr/share/gazebo/setup.bash && env PKGDEST=/ros2-common-pkg/artifact makepkg'" ]
