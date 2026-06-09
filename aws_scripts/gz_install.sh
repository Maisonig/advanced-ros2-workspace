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

# Проверка наличия ROS_DISTRO
if [ -z "$ROS_DISTRO" ]; then
    print_info "Переменная ROS_DISTRO не установлена. Пробуем определить..."
    if [ -f /opt/ros/jazzy/setup.bash ]; then
        source /opt/ros/jazzy/setup.bash
        print_success "Определена ROS2 Jazzy"
    elif [ -f /opt/ros/humble/setup.bash ]; then
        source /opt/ros/humble/setup.bash
        print_success "Определена ROS2 Humble"
    else
        echo -e "${RED}✗ Не удалось определить ROS_DISTRO. Установите ROS2 перед запуском этого скрипта.${NC}"
        exit 1
    fi
fi

# Главная установка
clear
print_header "УСТАНОВКА GAZEBO HARMONIC И ROS-GZ"

sleep 3

print_info "Установка зависимостей (curl, lsb-release, gnupg)..."
run_cmd "sudo apt-get update"
run_cmd "sudo apt-get install curl lsb-release gnupg -y"

print_info "Добавление ключа репозитория Gazebo..."
run_cmd "sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg"

print_info "Добавление репозитория Gazebo Stable..."
run_cmd "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null"

print_info "Обновление списка пакетов..."
run_cmd "sudo apt-get update"

print_info "Установка Gazebo Harmonic..."
run_cmd "sudo apt-get install gz-harmonic -y"

print_info "Установка интеграции ROS-Gazebo (ros-${ROS_DISTRO}-ros-gz)..."
run_cmd "sudo apt-get install ros-${ROS_DISTRO}-ros-gz -y"

print_success "Gazebo Harmonic и интеграция с ROS2 успешно установлены!"

# Проверка установки
echo -e "\n${YELLOW}Проверить установку Gazebo? (y/n)${NC}"
read -r run_gazebo
if [[ $run_gazebo == "y" || $run_gazebo == "Y" ]]; then
    print_info "Запуск Gazebo Harmonic (закройте окно для продолжения)..."
    sleep 1
    gz sim
fi

echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}         УСТАНОВКА GAZEBO HARMONIC ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "\n${CYAN}Полезные команды:${NC}"
echo -e "  gz sim - запуск симулятора"
echo -e "  gz sim -v 4 - запуск с подробным логированием"
echo -e "  ros2 gazebo — список пакетов интеграции ROS-Gazebo"
echo -e "\n"