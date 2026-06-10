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
print_header "УСТАНОВКА ZED CAMERA SDK И ROS2 WRAPPER"

# Шаг 1: Инструкция по скачиванию SDK
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
print_info "ШАГ 1: СКАЧИВАНИЕ ZED SDK"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Пожалуйста, скачайте ZED SDK для Ubuntu 24.04:${NC}"
echo -e "${BLUE}🔗 https://www.stereolabs.com/en-hk/developers/release${NC}"
echo -e ""
echo -e "${CYAN}Инструкция:${NC}"
echo -e "  1. Откройте ссылку в браузере"
echo -e "  2. Выберите версию для Ubuntu 24.04"
echo -e "  3. Скачайте .run файл в папку ~/Downloads"
echo -e ""
echo -e "${YELLOW}После того как файл скачан, нажмите Enter для продолжения...${NC}"
read -r

# Шаг 2: Установка zstd и поиск файла SDK
print_info "Установка zstd..."
run_cmd "sudo apt install zstd -y"

print_info "Поиск файла ZED SDK в ~/Downloads..."
ZED_FILE=$(ls ~/Downloads/ZED_SDK_Ubuntu24*.run 2>/dev/null | head -n 1)

if [[ -z "$ZED_FILE" ]]; then
    print_error "Файл ZED SDK не найден в ~/Downloads"
    print_info "Убедитесь, что файл ZED_SDK_Ubuntu24*.run скачан в папку Downloads"
    exit 1
fi

print_success "Найден файл: $(basename $ZED_FILE)"

# Шаг 3: Установка SDK
print_info "Делаем файл исполняемым..."
run_cmd "chmod +x $ZED_FILE"

print_info "Запуск установки ZED SDK"
print_warning "Установка может занять несколько минут..."
run_cmd "$ZED_FILE"

if [ $? -eq 0 ]; then
    print_success "ZED SDK успешно установлен"
else
    print_error "Ошибка при установке ZED SDK"
    exit 1
fi

# Шаг 4: Ввод пути до рабочей области
echo -e "\n${CYAN}════════════════════════════════════════════════════════════════${NC}"
print_info "ШАГ 2: УСТАНОВКА ROS2 WRAPPER"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"

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

# Шаг 5: Переход в рабочую область
print_info "Переход в рабочую область..."
run_cmd "cd $workspace_path"
cd "$workspace_path" || { print_error "Не удалось перейти в $workspace_path"; exit 1; }

# Шаг 6: Создание директории zed в src
print_info "Создание директории zed в src..."
run_cmd "cd src"
run_cmd "mkdir -p zed"
run_cmd "cd zed"
ZED_DIR="$workspace_path/src/zed"
print_success "Директория zed: $ZED_DIR"

# Шаг 7: Установка ZED ROS пакетов
print_info "Установка ZED ROS2 пакетов..."
run_cmd "sudo apt update"
run_cmd "sudo apt install ros-$ROS_DISTRO-zed-msgs -y"

# Шаг 8: Проверка на существование репозитория
print_info "Проверка наличия уже установленного репозитория zed-ros2-wrapper..."
if [[ -d "$ZED_DIR/zed-ros2-wrapper" ]]; then
    print_warning "Обнаружен существующий репозиторий zed-ros2-wrapper"
    echo -e "${YELLOW}Удалить существующую папку и продолжить установку? (y/n)${NC}"
    read -r remove_existing
    if [[ $remove_existing == "y" || $remove_existing == "Y" ]]; then
        print_info "Удаление существующего репозитория..."
        run_cmd "rm -rf zed-ros2-wrapper"
        print_success "Старый репозиторий удален"
    else
        print_error "Установка прервана пользователем"
        exit 1
    fi
fi

# Шаг 9: Клонирование zed-ros2-wrapper
print_info "Клонирование zed-ros2-wrapper из GitHub..."
run_cmd "git clone https://github.com/stereolabs/zed-ros2-wrapper.git"
if [ $? -ne 0 ]; then
    print_error "Не удалось клонировать zed-ros2-wrapper"
    exit 1
fi
print_success "Репозиторий успешно клонирован"

# Шаг 10: Возврат в корень рабочей области
print_info "Возврат в корень рабочей области..."
run_cmd "cd $workspace_path"

# Шаг 11: Обновление и установка зависимостей
print_info "Обновление системы и установка зависимостей..."
run_cmd "sudo apt update"
run_cmd "rosdep update"
run_cmd "rosdep install --from-paths src --ignore-src -r -y"

# Шаг 12: Сборка пакетов ZED
print_info "Сборка пакетов ZED ROS2 wrapper..."
print_info "Используется режим Release и все доступные ядра процессора"
run_cmd "colcon build --symlink-install --packages-select zed_components zed_ros2 zed_wrapper --cmake-args=-DCMAKE_BUILD_TYPE=Release --parallel-workers $(nproc)"

if [ $? -ne 0 ]; then
    print_error "Ошибка при сборке пакетов"
    print_info "Проверьте ошибки выше и попробуйте исправить"
    exit 1
fi

print_success "ZED ROS2 wrapper успешно собран"

# Шаг 13: Проверка камеры
echo -e "\n${YELLOW}Проверить работу ZED камеры? (y/n)${NC}"
echo -e "${CYAN}ℹ${NC} Убедитесь, что ZED камера подключена к компьютеру"
echo -e "${CYAN}ℹ${NC} Поддерживаемые модели: ZED, ZED2, ZED2i, ZED-X"
read -r run_test

if [[ $run_test == "y" || $run_test == "Y" ]]; then
    print_info "Загрузка окружения рабочей области..."
    source "$workspace_path/install/setup.bash"
    print_success "Окружение загружено"

    echo -e "${CYAN}ℹ${NC} Выберите модель камеры:"
    echo -e "  1) ZED"
    echo -e "  2) ZED2"
    echo -e "  3) ZED2i"
    echo -e "  4) ZED-X"
    read -r camera_choice

    case $camera_choice in
        1) CAMERA_MODEL="zed" ;;
        2) CAMERA_MODEL="zed2" ;;
        3) CAMERA_MODEL="zed2i" ;;
        4) CAMERA_MODEL="zed_x" ;;
        *) CAMERA_MODEL="zed2" ;;
    esac

    print_info "Запуск ZED камеры (модель: $CAMERA_MODEL)..."
    print_warning "Для остановки нажмите Ctrl+C"
    sleep 2
    ros2 launch zed_wrapper zed_camera.launch.py camera_model:=$CAMERA_MODEL
fi

# Финальная информация
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}         УСТАНОВКА ZED CAMERA SDK ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Установленные компоненты:${NC}"
echo -e "  🎥 ZED SDK - драйвер и SDK для ZED камер"
echo -e "  📦 zed_components - компоненты ZED"
echo -e "  🐛 zed_debug - инструменты отладки"
echo -e "  🔗 zed_ros2 - интеграция с ROS2"
echo -e "  📦 zed_wrapper - основной wrapper"

echo -e "\n${CYAN}Расположение:${NC}"
echo -e "  📁 Пакет: ${GREEN}$workspace_path/src/zed/zed-ros2-wrapper${NC}"
echo -e "  🔧 Сборка: ${GREEN}$workspace_path/build/${NC}"
echo -e "  📦 Установка: ${GREEN}$workspace_path/install/${NC}"
echo -e "  🎥 ZED SDK: ${GREEN}/usr/local/zed/"

echo -e "\n${CYAN}Для запуска ZED камеры в новом терминале выполните:${NC}"
echo -e "  ${YELLOW}source $workspace_path/install/setup.bash${NC}"
echo -e "  ${YELLOW}ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zed2${NC}"

echo -e "\n${CYAN}Полезные команды:${NC}"
echo -e "  Проверка SDK:                    ${YELLOW}ZED_Diagnostic${NC}"
echo -e "  Запуск ZED Explorer:             ${YELLOW}ZED_Explorer${NC}"
echo -e "  Просмотр топиков:                ${YELLOW}ros2 topic list | grep zed${NC}"
echo -e "  Просмотр RGB топика:             ${YELLOW}ros2 topic echo /zed/zed_node/rgb/image_rect_color${NC}"
echo -e "  Просмотр Depth топика:           ${YELLOW}ros2 topic echo /zed/zed_node/depth/depth_registered${NC}"
echo -e "  Просмотр PointCloud:             ${YELLOW}ros2 topic echo /zed/zed_node/point_cloud/points${NC}"

echo -e "\n${CYAN}Для разных моделей камер:${NC}"
echo -e "  ZED:    ${YELLOW}camera_model:=zed${NC}"
echo -e "  ZED2:   ${YELLOW}camera_model:=zed2${NC}"
echo -e "  ZED2i:  ${YELLOW}camera_model:=zed2i${NC}"
echo -e "  ZED-X:  ${YELLOW}camera_model:=zed_x${NC}"

echo -e "\n${CYAN}Документация:${NC}"
echo -e "  📖 https://www.stereolabs.com/docs/ros2"
echo -e "  📖 https://github.com/stereolabs/zed-ros2-wrapper"

echo -e "\n"