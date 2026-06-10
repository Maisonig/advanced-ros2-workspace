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
print_header "УСТАНОВКА RPLIDAR ROS2 ДРАЙВЕРА"

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

# Шаг 3: Создание директории rplidar в src
print_info "Создание директории rplidar в src..."
run_cmd "cd src"
run_cmd "mkdir -p rplidar"
run_cmd "cd rplidar"
RPLIDAR_DIR="$workspace_path/src/rplidar"
print_success "Директория rplidar: $RPLIDAR_DIR"

# Шаг 4: Проверка на существование репозитория
print_info "Проверка наличия уже установленного репозитория rplidar_ros..."
if [[ -d "$RPLIDAR_DIR/rplidar_ros" ]]; then
    print_warning "Обнаружен существующий репозиторий rplidar_ros"
    echo -e "${YELLOW}Удалить существующую папку и продолжить установку? (y/n)${NC}"
    read -r remove_existing
    if [[ $remove_existing == "y" || $remove_existing == "Y" ]]; then
        print_info "Удаление существующего репозитория..."
        run_cmd "rm -rf rplidar_ros"
        print_success "Старый репозиторий удален"
    else
        print_error "Установка прервана пользователем"
        exit 1
    fi
fi

# Шаг 5: Клонирование rplidar_ros
print_info "Клонирование rplidar_ros из GitHub (ветка ros2)..."
run_cmd "git clone -b ros2 https://github.com/Slamtec/rplidar_ros.git"
if [ $? -ne 0 ]; then
    print_error "Не удалось клонировать rplidar_ros"
    exit 1
fi
print_success "Репозиторий успешно клонирован"

# Шаг 6: Возврат в корень рабочей области
print_info "Возврат в корень рабочей области..."
run_cmd "cd $workspace_path"

# Шаг 7: Сборка пакета rplidar_ros
print_info "Сборка пакета rplidar_ros..."
run_cmd "colcon build --symlink-install --packages-select rplidar_ros"

if [ $? -ne 0 ]; then
    print_error "Ошибка при сборке пакета"
    print_info "Проверьте ошибки выше и попробуйте исправить"
    exit 1
fi

print_success "Пакет rplidar_ros успешно собран"

# Шаг 8: Загрузка окружения
print_info "Загрузка окружения рабочей области..."
run_cmd "source $workspace_path/install/setup.bash"

# Шаг 9: Создание udev правил
print_info "Создание udev правил для RPLiDAR..."
run_cmd "cd src/rplidar/rplidar_ros"
if [[ -f "scripts/create_udev_rules.sh" ]]; then
    run_cmd "source scripts/create_udev_rules.sh"
    print_success "udev правила созданы"
else
    print_error "Скрипт create_udev_rules.sh не найден"
    print_info "Проверьте путь: $workspace_path/src/rplidar/rplidar_ros/scripts/"
fi

# Шаг 10: Перезагрузка systemd
print_info "Перезагрузка systemd..."
run_cmd "sudo systemctl daemon-reload"
print_success "systemd перезагружен"

# Шаг 11: Возврат в корень рабочей области
run_cmd "cd $workspace_path"

# Проверка подключения лидара
echo -e "\n${YELLOW}Проверить подключение RPLiDAR? (y/n)${NC}"
echo -e "${CYAN}ℹ${NC} Убедитесь, что RPLiDAR подключен к компьютеру через USB"
read -r check_lidar

if [[ $check_lidar == "y" || $check_lidar == "Y" ]]; then
    print_info "Поиск устройства RPLiDAR..."

    # Поиск USB устройств Slamtec
    if lsusb | grep -i "Slamtec" > /dev/null || ls /dev/ttyUSB* 2>/dev/null | grep -q "ttyUSB"; then
        print_success "RPLiDAR обнаружен!"
        print_info "Устройство найдено в /dev/ttyUSB0 (или аналогичном)"

        echo -e "\n${YELLOW}Запустить RPLiDAR ноду для проверки? (y/n)${NC}"
        echo -e "${CYAN}⚠️  ВНИМАНИЕ: Для работы лидара может потребоваться указать правильный порт в launch файле${NC}"
        read -r run_lidar

        if [[ $run_lidar == "y" || $run_lidar == "Y" ]]; then
            print_info "Запуск RPLiDAR A1 (стандартный launch файл)..."
            print_warning "Для остановки нажмите Ctrl+C"
            sleep 2
            ros2 launch rplidar_ros view_rplidar_a1_launch.py
        fi
    else
        print_warning "RPLiDAR не обнаружен"
        print_info "Проверьте:"
        echo -e "  1. Подключен ли лидар к USB порту"
        echo -e "  2. Есть ли права доступа к порту"
        echo -e "  3. Можно запустить вручную после подключения:"
        echo -e "     ${YELLOW}ros2 launch rplidar_ros view_rplidar_a1_launch.py${NC}"
    fi
fi

# Финальная информация
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}         УСТАНОВКА RPLIDAR ROS2 ДРАЙВЕРА ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Установленные компоненты:${NC}"
echo -e "  🎯 rplidar_ros - драйвер RPLiDAR для ROS2"

echo -e "\n${CYAN}Расположение:${NC}"
echo -e "  📁 Пакет: ${GREEN}$workspace_path/src/rplidar/rplidar_ros${NC}"
echo -e "  🔧 Сборка: ${GREEN}$workspace_path/build/rplidar_ros${NC}"
echo -e "  📦 Установка: ${GREEN}$workspace_path/install/rplidar_ros${NC}"

echo -e "\n${CYAN}Для запуска RPLiDAR в новом терминале выполните:${NC}"
echo -e "  ${YELLOW}source $workspace_path/install/setup.bash${NC}"
echo -e "  ${YELLOW}ros2 launch rplidar_ros view_rplidar_a1_launch.py${NC}"

echo -e "\n${CYAN}Для других моделей RPLiDAR:${NC}"
echo -e "  A2: ${YELLOW}ros2 launch rplidar_ros view_rplidar_a2_launch.py${NC}"
echo -e "  A3: ${YELLOW}ros2 launch rplidar_ros view_rplidar_a3_launch.py${NC}"
echo -e "  C1: ${YELLOW}ros2 launch rplidar_ros view_rplidar_c1_launch.py${NC}"
echo -e "  S1: ${YELLOW}ros2 launch rplidar_ros view_rplidar_s1_launch.py${NC}"

echo -e "\n${CYAN}Полезные команды:${NC}"
echo -e "  Проверить подключение лидара:   ${YELLOW}lsusb | grep Slamtec${NC}"
echo -e "  Найти порт лидара:              ${YELLOW}ls /dev/ttyUSB*${NC}"
echo -e "  Дать права доступа к порту:     ${YELLOW}sudo chmod 666 /dev/ttyUSB0${NC}"
echo -e "  Просмотр топиков лидара:        ${YELLOW}ros2 topic list | grep scan${NC}"
echo -e "  Просмотр данных сканирования:   ${YELLOW}ros2 topic echo /scan${NC}"

echo -e "\n${CYAN}Документация:${NC}"
echo -e "  📖 https://github.com/Slamtec/rplidar_ros"

echo -e "\n"
