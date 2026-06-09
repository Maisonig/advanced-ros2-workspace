#!/bin/bash

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
ORANGE='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Функция для красивого заголовка
print_header() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${PURPLE}${BOLD}          $1${NC}${BLUE}                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

# Функция для успешного завершения
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Функция для информации
print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Функция для выполнения команды
run_cmd() {
    echo -e "${YELLOW}▶${NC} $1"
    eval $1
    if [ $? -eq 0 ]; then
        print_success "Выполнено"
    else
        echo -e "${RED}✗ Ошибка при выполнении: $1${NC}"
        exit 1
    fi
    echo ""
}

# ROS2 Jazzy установка
print_header "УСТАНОВКА ROS2 JAZZY"

sleep 3

print_info "Проверка настроек локалей..."
run_cmd "locale"

print_info "Установка и настройка локальных параметров..."
run_cmd "sudo apt update && sudo apt install locales -y"
run_cmd "sudo locale-gen en_US en_US.UTF-8"
run_cmd "sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8"
run_cmd "export LANG=en_US.UTF-8"

print_info "Проверка настроек локалей после изменений..."
run_cmd "locale"

print_info "Установка software-properties-common..."
run_cmd "sudo apt install software-properties-common -y"

print_info "Добавление репозитория universe..."
run_cmd "sudo add-apt-repository universe -y"

print_info "Установка curl..."
run_cmd "sudo apt update && sudo apt install curl -y"

print_info "Загрузка и установка ROS APT source..."
run_cmd "export ROS_APT_SOURCE_VERSION=\$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F 'tag_name' | awk -F'\"' '{print \$4}')"
run_cmd "curl -L -o /tmp/ros2-apt-source.deb \"https://github.com/ros-infrastructure/ros-apt-source/releases/download/\${ROS_APT_SOURCE_VERSION}/ros2-apt-source_\${ROS_APT_SOURCE_VERSION}.\$(. /etc/os-release && echo \${UBUNTU_CODENAME:-\${VERSION_CODENAME}})_all.deb\""
run_cmd "sudo dpkg -i /tmp/ros2-apt-source.deb"

print_info "Установка ROS development tools..."
run_cmd "sudo apt update && sudo apt install ros-dev-tools -y"

print_info "Обновление списка пакетов..."
run_cmd "sudo apt update"

print_info "Обновление системы..."
run_cmd "sudo apt upgrade -y"

print_info "Установка ROS2 Jazzy Desktop..."
run_cmd "sudo apt install ros-jazzy-desktop -y"

print_info "Настройка окружения ROS2..."
run_cmd "source /opt/ros/jazzy/setup.bash"

print_success "ROS2 Jazzy успешно установлен!"

# Добавление в .bashrc
echo -e "\n${YELLOW}Добавить source /opt/ros/jazzy/setup.bash в .bashrc? (y/n)${NC}"
read -r add_to_bashrc
if [[ $add_to_bashrc == "y" || $add_to_bashrc == "Y" ]]; then
    if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc 2>/dev/null; then
        echo -e "\n# ROS2 Jazzy" >> ~/.bashrc
        echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
        print_success "Добавлено в .bashrc"
    else
        print_info "Запись уже присутствует в .bashrc"
    fi
fi

echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}            УСТАНОВКА ROS2 JAZZY ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "\n${CYAN}Для проверки установки выполните:${NC}"
echo -e "  source /opt/ros/jazzy/setup.bash"
echo -e "  ros2 --version"
echo -e "\n"