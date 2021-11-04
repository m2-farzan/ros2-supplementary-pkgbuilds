This project is not yet ready.

# How to contribute?

> So if you could point me in the right direction as to how I can build ROS packages from scratch I will be more than happy to contribute and upload them at the AUR

You can start by studying [xacro pkgbuild](https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=ros2-foxy-xacro) itself.

Most ROS packages are more complicated than xacro though. A ROS package can depend on other ROS packages, as well as non-ROS packages that install on OS itself. Furthermore, those dependencies that are ROS packages can themselves depend on ROS and non-ROS packages. This makes a recursive process until you reach simple packages with no special dependencies.

For example, here's my pkgbuild for `ros2-localization` package which I've not tested enough to publish in AUR.
```
# Maintainer: Mohammad Mostafa Farzan <m2_farzan@yahoo.com>

pkgname=ros2-robot-localization-git
pkgver=r991.212bfb0
pkgrel=1
pkgdesc="Slam Toolbox for lifelong mapping and localization in potentially massive maps with ROS 2"
url="https://navigation.ros.org/tutorials/docs/navigation2_with_slam.html"
arch=('any')
depends=('ros2-git'
         'ros2-navigation-git'
         'ros2-diagnostics-git'
         )
source=("robot_localization::git+https://github.com/cra-ros-pkg/robot_localization#branch=ros2"
        "git+https://github.com/ros-geographic-info/geographic_info#branch=ros2")
sha256sums=('SKIP'
            'SKIP')

pkgver() {
  cd $srcdir/robot_localization
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
    sed -i "s/c++14/c++17/g" $srcdir/robot_localization/CMakeLists.txt
}

build() {
    source /opt/ros2/rolling/setup.sh
    colcon build --merge-install
}

package() {
    # Copy build files
    mkdir -p $pkgdir/opt/ros2/rolling
    cp -r $srcdir/install/* $pkgdir/opt/ros2/rolling/
    # Exclude files that clash with base ros installation
    rm $pkgdir/opt/ros2/rolling/*setup.*
    rm $pkgdir/opt/ros2/rolling/_local_setup*
    rm $pkgdir/opt/ros2/rolling/COLCON_IGNORE
}

```
Note that the package depends on other ROS packages. For two of them I created separate pkgbuilds (`navigation`, `diagnostic`) because I felt they are common packages. For `geographic_info` I didn't bother making yet another pkgbuild. I just added clone instruction so that it'll be built by colcon before the main package—colcon automatically builds dependencies first. If later on I run into another package with `geographic_info` dependency, I'll refactor it as a new package. There are no strict rules, and IMO going too granular will just create clutter.

The base ros2-foxy (or ros2-git) package itself installs a few hundred base packages and all ROS packages depend on it.

So how to find out what are dependencies of a package? Here's some tips:
- `rosdep check --from-paths <package_source_path>` displays non-ROS dependencies of a package. You can find Arch equivalents by searching the names in https://www.archlinux.org/packages/ first and https://aur.archlinux.org/packages/.
- Studying `package.xml` should reveal ROS dependencies. Note that some of them are probably already installed by ros2-foxy or ros2-git. `ros2 pkg list | grep <package_name>` should help here. However, if you've also installed stuff from AUR they'll also show up in the list. To distinguish them, run the command like `ls /opt/ros2/rolling/share/ | grep xacro | xargs pacman -Qo` which reveals the pacman package that installed the ros package.
- Finally, you can lookup in [this file](http://packages.ros.org/ros2/ubuntu/lists/ros-rolling-focal-amd64_focal_main_amd64_Packages) which is package index for pre-built Ubuntu packages. It includes all sort of dependencies, and I find this method more convenient than the others. You still need to look up recursively. A script could help with the recursion. I'll make one if I get the time.
- Another way to list external, non-base dependencies quickly:
  ```bash
  cd fat_parent_package/src
  PROVIDED_PACKAGES_=$(find . -name package.xml | xargs dirname | xargs -L1 basename)
  DEPENDENCIES_=$(grep -RPoh "<(build|buildtool|exec|run)?_?depend>\K[^\<]+" | sort | uniq)
  BASE_PACKAGES_=$(pacman -Ql ros2-galactic | grep -oP "/share/\K[^/]+" | sort | uniq)
  comm -23 <(printf "${DEPENDENCIES_}") <(printf "${BASE_PACKAGES_}\n${PROVIDED_PACKAGES_}" | sort | uniq)
  ```

# Afterthought

I don't know if this one is a good idea. Anyway, I've been thinking about bundling all these packages into single bulky one like `ros2-galactic-most` (similar to texlive-most for example)

The reason that such package is viable is that Arch is rarely used for production. It's mostly a dev's workstation. So why bother with the granular packaging? We could just put the common packages in a single PKGBUILD. Of course the package will take more time to build but this would be a one-off nightly task. With the granular packages, the user will be interrupted frequently (in their work time) to find and build packages (or rebuild them every time python or a shared library bumps).

I think this approach gives better dev experience. It also complies with [Archlinux princliple](https://wiki.archlinux.org/title/Arch_Linux#Principles) of simplicity:
> Packages are only split when compelling advantages exist, such as to save disk space in particularly bad cases of waste.
