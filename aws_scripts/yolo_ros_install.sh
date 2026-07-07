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
    print_warning "Переменная ROS_DISTRO не установлена!"
    print_info "Пробуем определить автоматически..."

    if [ -f /opt/ros/jazzy/setup.bash ]; then
        source /opt/ros/jazzy/setup.bash
        print_success "Определена ROS2 Jazzy"
    elif [ -f /opt/ros/humble/setup.bash ]; then
        source /opt/ros/humble/setup.bash
        print_success "Определена ROS2 Humble"
    elif [ -f /opt/ros/foxy/setup.bash ]; then
        source /opt/ros/foxy/setup.bash
        print_success "Определена ROS2 Foxy"
    else
        print_error "Не удалось определить ROS_DISTRO"
        print_info "Пожалуйста, установите ROS2 или выполните: source /opt/ros/*/setup.bash"
        exit 1
    fi
fi

print_success "ROS_DISTRO = $ROS_DISTRO"

# Главная установка
clear
print_header "УСТАНОВКА YOLO ROS2"

# Шаг 1: Ввод пути до рабочей области
echo -e "${CYAN}ℹ${NC} Введите абсолютный путь до вашей рабочей области ROS2"
echo -e "${YELLOW}Пример: /home/$(whoami)/dev_ws${NC}"
echo -e -n "${YELLOW}Путь: ${NC}"
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

# Шаг 3: Создание директории yolo в src
print_info "Создание директории yolo в src..."
run_cmd "cd src"
run_cmd "mkdir -p yolo"
run_cmd "cd yolo"
YOLO_DIR="$workspace_path/src/yolo"
print_success "Директория yolo: $YOLO_DIR"

# Шаг 4: Проверка на существование репозитория
print_info "Проверка наличия уже установленного репозитория yolo_ros..."
if [[ -d "$YOLO_DIR/yolo_ros" ]]; then
    print_warning "Обнаружен существующий репозиторий yolo_ros"
    echo -e "${YELLOW}Удалить существующую папку и продолжить установку? (y/n)${NC}"
    read -r remove_existing
    if [[ $remove_existing == "y" || $remove_existing == "Y" ]]; then
        print_info "Удаление существующего репозитория..."
        run_cmd "rm -rf yolo_ros"
        print_success "Старый репозиторий удален"
    else
        print_error "Установка прервана пользователем"
        exit 1
    fi
fi

# Шаг 5: Клонирование yolo_ros
print_info "Клонирование yolo_ros из GitHub..."
run_cmd "git clone https://github.com/mgonzs13/yolo_ros.git"
if [ $? -ne 0 ]; then
    print_error "Не удалось клонировать yolo_ros"
    exit 1
fi
print_success "Репозиторий успешно клонирован"

# Шаг 6: Установка uv (менеджер пакетов Python)
print_info "Установка uv (менеджер пакетов Python)..."
run_cmd "curl -LsSf https://astral.sh/uv/install.sh | sh"

# Загрузка переменных окружения uv
print_info "Загрузка переменных окружения uv..."
if [ -f "$HOME/.bashrc" ]; then
    source ~/.bashrc
    print_success "Переменные окружения загружены из .bashrc"
else
    print_warning "Файл .bashrc не найден, продолжаем без загрузки"
fi

# Шаг 7: Установка зависимостей Python через uv
print_info "Переход в директорию yolo_ros..."
run_cmd "cd $YOLO_DIR/yolo_ros"

print_info "Установка Python зависимостей через uv..."
run_cmd "uv sync"

if [ $? -ne 0 ]; then
    print_warning "Возможная проблема с uv sync. Попробуйте установить зависимости вручную позже"
    print_info "Команда для ручной установки: cd $YOLO_DIR/yolo_ros && uv sync"
fi

# Шаг 8: Возврат в корень рабочей области
print_info "Возврат в корень рабочей области..."
run_cmd "cd $workspace_path"

# Шаг 9: Установка зависимостей через rosdep
print_info "Установка зависимостей через rosdep..."
run_cmd "rosdep install --from-paths src --ignore-src -r -y"

# Шаг 10: Сборка пакетов YOLO
print_info "Сборка пакетов YOLO ROS2..."
run_cmd "colcon build --packages-select yolo_ros yolo_msgs yolo_bringup"

if [ $? -ne 0 ]; then
    print_error "Ошибка при сборке пакетов"
    print_info "Проверьте ошибки выше и попробуйте исправить"
    exit 1
fi

# Шаг 11: Загрузка окружения
print_info "Загрузка окружения рабочей области..."
run_cmd "source install/setup.bash"

print_success "YOLO ROS2 успешно установлен и собран!"

# Финальная информация
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}            УСТАНОВКА YOLO ROS2 ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Установленные компоненты:${NC}"
echo -e "  🎯 yolo_ros     - основной пакет YOLO"
echo -e "  📨 yolo_msgs    - сообщения YOLO"
echo -e "  🚀 yolo_bringup - launch файлы для запуска"

echo -e "\n${CYAN}Расположение:${NC}"
echo -e "  📁 Пакет: ${GREEN}$workspace_path/src/yolo/yolo_ros${NC}"
echo -e "  🔧 Сборка: ${GREEN}$workspace_path/build/${NC}"
echo -e "  📦 Установка: ${GREEN}$workspace_path/install/${NC}"

echo -e "\n${CYAN}Для запуска YOLO в новом терминале выполните:${NC}"
echo -e "  ${YELLOW}source $workspace_path/install/setup.bash${NC}"
echo -e "  ${YELLOW}ros2 launch yolo_bringup yolo.launch.py${NC}"

echo -e "\n${CYAN}Полезные команды:${NC}"
echo -e "  Запуск с веб-камерой:        ${YELLOW}ros2 launch yolo_bringup yolo.launch.py use_camera:=true${NC}"
echo -e "  Запуск с видеофайлом:        ${YELLOW}ros2 launch yolo_bringup yolo.launch.py video_path:=/path/to/video.mp4${NC}"
echo -e "  Запуск с изображением:       ${YELLOW}ros2 launch yolo_bringup yolo.launch.py image_path:=/path/to/image.jpg${NC}"
echo -e "  Просмотр топиков:            ${YELLOW}ros2 topic list | grep yolo${NC}"
echo -e "  Просмотр детекций:           ${YELLOW}ros2 topic echo /yolo/detections${NC}"
echo -e "  Просмотр визуализации:       ${YELLOW}ros2 topic echo /yolo/image_with_detections${NC}"

echo -e "\n${CYAN}Настройка модели:${NC}"
echo -e "  По умолчанию используется YOLOv8n"
echo -e "  Для изменения модели отредактируйте:"
echo -e "  ${YELLOW}$workspace_path/src/yolo/yolo_ros/config/params.yaml${NC}"

echo -e "\n${CYAN}Документация:${NC}"
echo -e "  📖 https://github.com/mgonzs13/yolo_ros"

echo -e "\n${CYAN}⚠️  Важно:${NC}"
echo -e "  • Для работы с GPU требуется CUDA и cuDNN"
echo -e "  • При первом запуске модель будет загружена автоматически"
echo -e "  • Для использования веб-камеры установите: ${YELLOW}sudo apt install v4l-utils${NC}"

echo -e "\n"