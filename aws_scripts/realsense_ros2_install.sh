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

# Функция для ошибок
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Функция для предупреждений
print_warning() {
    echo -e "${ORANGE}⚠${NC} $1"
}

# Функция для выполнения команды
run_cmd() {
    echo -e "${YELLOW}▶${NC} $1"
    eval $1
    if [ $? -eq 0 ]; then
        print_success "Выполнено"
    else
        print_error "Ошибка при выполнении: $1"
        return 1
    fi
    echo ""
}

# Проверка наличия ROS_DISTRO
if [ -z "$ROS_DISTRO" ]; then
    print_error "Переменная ROS_DISTRO не установлена!"
    print_info "Пожалуйста, установите ROS2 сначала или запустите: source /opt/ros/jazzy/setup.bash"
    exit 1
fi

print_success "Обнаружена ROS2 дистрибуция: $ROS_DISTRO"

# Главная установка
clear
print_header "УСТАНОВКА ROS WRAPPER ДЛЯ INTEL REALSENSE"

# Шаг 1: Ввод пути до рабочей области
echo -e "${CYAN}ℹ${NC} Введите абсолютный путь до вашей рабочей области ROS2"
echo -e "${YELLOW}Пример: /home/$(whoami)/dev_ws${NC}"
echo -e "${YELLOW}Путь: ${NC}"
read -r workspace_path

# Проверка, что путь не пустой
if [[ -z "$workspace_path" ]]; then
    print_error "Путь не может быть пустым"
    exit 1
fi

# Проверка существования директории
if [[ ! -d "$workspace_path" ]]; then
    print_error "Директория $workspace_path не существует"
    print_info "Пожалуйста, создайте рабочую область ROS2 сначала"
    exit 1
fi

# Проверка наличия src директории
if [[ ! -d "$workspace_path/src" ]]; then
    print_error "Директория src не найдена в $workspace_path"
    print_info "Убедитесь, что это правильная рабочая область ROS2"
    exit 1
fi

print_success "Рабочая область: $workspace_path"

# Шаг 2: Переход в рабочую область
print_info "Переход в рабочую область..."
run_cmd "cd $workspace_path"
cd "$workspace_path" || { print_error "Не удалось перейти в $workspace_path"; exit 1; }

# Шаг 3: Создание директории realsense в src
print_info "Создание директории realsense в src..."
run_cmd "cd src"
run_cmd "mkdir -p realsense"
run_cmd "cd realsense"
REALSENSE_DIR="$workspace_path/src/realsense"
print_success "Директория realsense: $REALSENSE_DIR"

# Шаг 4: Установка пакетов librealsense2 для ROS
print_info "Установка пакетов librealsense2 для ROS2 $ROS_DISTRO..."
run_cmd "sudo apt install ros-$ROS_DISTRO-librealsense2* -y"

# Шаг 5: Проверка на существование репозитория
print_info "Проверка наличия уже установленного репозитория realsense-ros..."
if [[ -d "$REALSENSE_DIR/realsense-ros" ]]; then
    print_warning "Обнаружен существующий репозиторий realsense-ros"
    echo -e "${YELLOW}Удалить существующую папку и продолжить установку? (y/n)${NC}"
    read -r remove_existing
    if [[ $remove_existing == "y" || $remove_existing == "Y" ]]; then
        print_info "Удаление существующего репозитория..."
        run_cmd "rm -rf realsense-ros"
        print_success "Старый репозиторий удален"
    else
        print_error "Установка прервана пользователем"
        exit 1
    fi
fi

# Шаг 6: Клонирование realsense-ros
print_info "Клонирование realsense-ros из GitHub (ветка ros2-master)..."
run_cmd "git clone https://github.com/realsenseai/realsense-ros.git -b ros2-master"
if [ $? -ne 0 ]; then
    print_error "Не удалось клонировать realsense-ros"
    exit 1
fi
print_success "Репозиторий успешно клонирован"

# Шаг 7: Возврат в корень рабочей области
print_info "Возврат в корень рабочей области..."
run_cmd "cd $workspace_path"

# Шаг 8: Установка python3-rosdep
print_info "Установка python3-rosdep..."
run_cmd "sudo apt-get install python3-rosdep -y"

# Шаг 9: Инициализация rosdep
print_info "Инициализация rosdep..."
if [ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
    if [[ "$ROS_DISTRO" == "foxy" ]] || [[ "$ROS_DISTRO" == "eloquent" ]] || [[ "$ROS_DISTRO" == "dashing" ]]; then
        print_warning "Обнаружена EOL версия ROS2 ($ROS_DISTRO), используем --include-eol-distros"
        run_cmd "sudo rosdep init --include-eol-distros"
    else
        run_cmd "sudo rosdep init"
    fi
else
    print_info "rosdep уже инициализирован"
fi

# Шаг 10: Обновление rosdep
print_info "Обновление rosdep..."
if [[ "$ROS_DISTRO" == "foxy" ]] || [[ "$ROS_DISTRO" == "eloquent" ]] || [[ "$ROS_DISTRO" == "dashing" ]]; then
    run_cmd "rosdep update --include-eol-distros"
else
    run_cmd "rosdep update"
fi

# Шаг 11: Установка зависимостей через rosdep
print_info "Установка зависимостей через rosdep..."
run_cmd "rosdep install -i --from-path src --rosdistro $ROS_DISTRO --skip-keys=librealsense2 -y"

# Шаг 12: Сборка пакетов RealSense
print_info "Сборка пакетов RealSense..."
run_cmd "colcon build --packages-select realsense2_camera realsense2_camera_msgs realsense2_description realsense2_rgbd_plugin realsense2_ros_mqtt_bridge"

if [ $? -ne 0 ]; then
    print_error "Ошибка при сборке пакетов"
    print_info "Проверьте ошибки выше и попробуйте исправить"
    exit 1
fi

print_success "RealSense ROS wrapper успешно установлен и собран!"

# Шаг 13: Проверка установки (без добавления в .bashrc)
echo -e "\n${YELLOW}Проверить работу RealSense камеры? (y/n)${NC}"
echo -e "${CYAN}ℹ${NC} Убедитесь, что камера RealSense подключена к компьютеру"
read -r run_test

if [[ $run_test == "y" || $run_test == "Y" ]]; then
    print_info "Загрузка окружения рабочей области..."
    source "$workspace_path/install/setup.bash"
    print_success "Окружение загружено"

    print_info "Запуск ноды RealSense камеры..."
    print_warning "Для остановки нажмите Ctrl+C"
    sleep 2
    ros2 launch realsense2_camera rs_launch.py
fi

# Финальная информация
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}      УСТАНОВКА REALSENSE ROS WRAPPER ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Установленные пакеты:${NC}"
echo -e "  📷 realsense2_camera       - драйвер камеры"
echo -e "  📨 realsense2_camera_msgs  - сообщения для камеры"
echo -e "  📄 realsense2_description  - URDF модель камеры"
echo -e "  🎨 realsense2_rgbd_plugin  - RGBD плагин"
echo -e "  🔌 realsense2_ros_mqtt_bridge - MQTT мост"

echo -e "\n${CYAN}Расположение:${NC}"
echo -e "  📁 Пакеты: ${GREEN}$workspace_path/src/realsense/realsense-ros${NC}"
echo -e "  🔧 Сборка: ${GREEN}$workspace_path/build/${NC}"
echo -e "  📦 Установка: ${GREEN}$workspace_path/install/${NC}"

echo -e "\n${CYAN}Для запуска камеры в новом терминале выполните:${NC}"
echo -e "  ${YELLOW}source $workspace_path/install/setup.bash${NC}"
echo -e "  ${YELLOW}ros2 launch realsense2_camera rs_launch.py${NC}"

echo -e "\n${CYAN}Полезные команды:${NC}"
echo -e "  Просмотр топиков:                 ${YELLOW}ros2 topic list | grep realsense${NC}"
echo -e "  Просмотр RGB топика:              ${YELLOW}ros2 topic echo /camera/color/image_raw${NC}"
echo -e "  Просмотр Depth топика:            ${YELLOW}ros2 topic echo /camera/depth/image_rect_raw${NC}"

echo -e "\n${CYAN}Документация:${NC}"
echo -e "  📖 https://github.com/IntelRealSense/realsense-ros"

echo -e "\n"