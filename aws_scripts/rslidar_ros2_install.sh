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

# Главная установка
clear
print_header "УСТАНОВКА ROBOSENSE LIDAR SDK"

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

# Шаг 3: Создание директории rslidar в src
print_info "Создание директории rslidar в src..."
run_cmd "cd src"
run_cmd "mkdir -p rslidar"
run_cmd "cd rslidar"
RSLIDAR_DIR="$workspace_path/src/rslidar"
print_success "Директория rslidar: $RSLIDAR_DIR"

# Шаг 4: Проверка на существование репозиториев
print_info "Проверка наличия уже установленных репозиториев..."
if [[ -d "$RSLIDAR_DIR/rslidar_sdk" ]] || [[ -d "$RSLIDAR_DIR/rslidar_msg" ]]; then
    print_warning "Обнаружены существующие репозитории rslidar_sdk или rslidar_msg"
    echo -e "${YELLOW}Удалить существующие папки и продолжить установку? (y/n)${NC}"
    read -r remove_existing
    if [[ $remove_existing == "y" || $remove_existing == "Y" ]]; then
        print_info "Удаление существующих репозиториев..."
        run_cmd "rm -rf rslidar_sdk rslidar_msg"
        print_success "Старые репозитории удалены"
    else
        print_error "Установка прервана пользователем"
        exit 1
    fi
fi

# Шаг 5: Клонирование rslidar_sdk
print_info "Клонирование rslidar_sdk из GitHub..."
run_cmd "git clone https://github.com/RoboSense-LiDAR/rslidar_sdk.git"
if [ $? -ne 0 ]; then
    print_error "Не удалось клонировать rslidar_sdk"
    exit 1
fi

# Шаг 6: Инициализация и обновление подмодулей
print_info "Инициализация подмодулей rslidar_sdk..."
run_cmd "cd rslidar_sdk"
run_cmd "git submodule init"
run_cmd "git submodule update"
run_cmd "cd .."

# Шаг 7: Клонирование rslidar_msg
print_info "Клонирование rslidar_msg из GitHub..."
run_cmd "git clone https://github.com/RoboSense-LiDAR/rslidar_msg.git"
if [ $? -ne 0 ]; then
    print_error "Не удалось клонировать rslidar_msg"
    exit 1
fi

# Шаг 8: Установка системных зависимостей
print_info "Установка системных зависимостей..."
run_cmd "sudo apt-get update"
run_cmd "sudo apt-get install -y libyaml-cpp-dev"
run_cmd "sudo apt-get install -y libpcap-dev"

# Шаг 9: Возврат в корень рабочей области
print_info "Возврат в корень рабочей области..."
run_cmd "cd $workspace_path"

# Шаг 10: Сборка пакетов
print_info "Сборка пакетов rslidar_sdk и rslidar_msg..."
run_cmd "colcon build --packages-select rslidar_sdk rslidar_msg"

if [ $? -ne 0 ]; then
    print_error "Ошибка при сборке пакетов"
    print_info "Проверьте ошибки выше и попробуйте исправить"
    exit 1
fi

# Шаг 11: Настройка окружения
print_info "Настройка окружения для работы с пакетами..."
run_cmd "source install/setup.bash"
run_cmd "echo 'source $workspace_path/install/setup.bash' >> ~/.bashrc"

print_success "RoboSense LiDAR SDK успешно установлен и собран!"

# Шаг 12: Проверка установки
echo -e "\n${YELLOW}Проверить работу rslidar_sdk_node? (y/n)${NC}"
echo -e "${CYAN}ℹ${NC} Для проверки нужен подключенный LiDAR или будет ошибка ERRCODE_MSOPTIMEOUT"
read -r run_test

if [[ $run_test == "y" || $run_test == "Y" ]]; then
    print_info "Запуск rslidar_sdk_node..."
    print_warning "Если LiDAR не подключен, вы увидите ошибку ERRCODE_MSOPTIMEOUT - это нормально"
    sleep 2
    ros2 run rslidar_sdk rslidar_sdk_node
fi

# Финальная информация
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}         УСТАНОВКА ROBOSENSE LIDAR SDK ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Установленные компоненты:${NC}"
echo -e "  📦 rslidar_sdk - драйвер и SDK для LiDAR"
echo -e "  📨 rslidar_msg - сообщения ROS2 для LiDAR"

echo -e "\n${CYAN}Расположение:${NC}"
echo -e "  📁 Пакеты: ${GREEN}$workspace_path/src/rslidar/${NC}"
echo -e "  🔧 Сборка: ${GREEN}$workspace_path/build/${NC}"
echo -e "  📦 Установка: ${GREEN}$workspace_path/install/${NC}"

echo -e "\n${CYAN}Полезные команды:${NC}"
echo -e "  Запуск ноды:              ${YELLOW}ros2 run rslidar_sdk rslidar_sdk_node${NC}"
echo -e "  Проверка топиков:         ${YELLOW}ros2 topic list${NC}"
echo -e "  Просмотр данных LiDAR:    ${YELLOW}ros2 topic echo /rslidar_points${NC}"
echo -e "  Пересборка пакетов:       ${YELLOW}colcon build --packages-select rslidar_sdk rslidar_msg${NC}"

echo -e "\n${CYAN}Настройка порта LiDAR:${NC}"
echo -e "  Отредактируйте файл конфигурации:"
echo -e "  ${YELLOW}$workspace_path/src/rslidar/rslidar_sdk/config/config.yaml${NC}"
echo -e "  Укажите правильный порт (например, /dev/ttyUSB0)"

echo -e "\n${CYAN}Документация:${NC}"
echo -e "  📖 https://github.com/RoboSense-LiDAR/rslidar_sdk"
echo -e "  📖 https://github.com/RoboSense-LiDAR/rslidar_msg"

echo -e "\n"