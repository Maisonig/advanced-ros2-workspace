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
print_header "УСТАНОВКА INTEL REALSENSE SDK"

# Шаг 1: Создание директории для ключей
print_info "Создание директории для ключей apt..."
run_cmd "sudo mkdir -p /etc/apt/keyrings"

# Шаг 2: Добавление ключа репозитория RealSense
print_info "Добавление ключа репозитория Intel RealSense..."
run_cmd "curl -sSf https://librealsense.realsenseai.com/Debian/librealsenseai.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/librealsenseai.gpg > /dev/null"

# Шаг 3: Установка apt-transport-https
print_info "Установка apt-transport-https..."
run_cmd "sudo apt-get install apt-transport-https -y"

# Шаг 4: Добавление репозитория RealSense
print_info "Добавление репозитория Intel RealSense..."
CODENAME=$(lsb_release -cs)
run_cmd "echo \"deb [signed-by=/etc/apt/keyrings/librealsenseai.gpg] https://librealsense.realsenseai.com/Debian/apt-repo $CODENAME main\" | sudo tee /etc/apt/sources.list.d/librealsense.list > /dev/null"
print_success "Репозиторий добавлен для дистрибутива: $CODENAME"

# Шаг 5: Обновление списка пакетов
print_info "Обновление списка пакетов..."
run_cmd "sudo apt-get update"

# Шаг 6: Установка модуля ядра (DKMS)
print_info "Установка модуля ядра RealSense (DKMS)..."
run_cmd "sudo apt-get install librealsense2-dkms -y"

# Шаг 7: Установка утилит
print_info "Установка утилит RealSense..."
run_cmd "sudo apt-get install librealsense2-utils -y"

# Шаг 8: Установка библиотек разработки
print_info "Установка библиотек разработки RealSense..."
run_cmd "sudo apt-get install librealsense2-dev -y"

# Шаг 9: Установка отладочных символов
print_info "Установка отладочных символов RealSense..."
run_cmd "sudo apt-get install librealsense2-dbg -y"

# Шаг 10: Финальное обновление системы
print_info "Финальное обновление системы..."
run_cmd "sudo apt-get update"
run_cmd "sudo apt-get upgrade -y"

print_success "Intel RealSense SDK успешно установлен!"

# Проверка установки
echo -e "\n${YELLOW}Проверить установку RealSense? (y/n)${NC}"
read -r run_test
if [[ $run_test == "y" || $run_test == "Y" ]]; then
    print_info "Запуск утилиты realsense-viewer..."
    print_warning "Убедитесь, что камера RealSense подключена к компьютеру"
    sleep 2
    realsense-viewer
fi

# Информация о установленных компонентах
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}         УСТАНОВКА INTEL REALSENSE SDK ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Установленные компоненты:${NC}"
echo -e "  📦 librealsense2-dkms   - модуль ядра"
echo -e "  🛠️  librealsense2-utils  - утилиты (realsense-viewer)"
echo -e "  🔧 librealsense2-dev    - библиотеки разработки"
echo -e "  🐛 librealsense2-dbg    - отладочные символы"

echo -e "\n${CYAN}Полезные команды:${NC}"
echo -e "  Запуск просмотрщика:     ${YELLOW}realsense-viewer${NC}"
echo -e "  Проверка версии:         ${YELLOW}dpkg -l | grep librealsense${NC}"
echo -e "  Проверка подключения:    ${YELLOW}rs-enumerate-devices${NC}"

echo -e "\n${CYAN}Документация:${NC}"
echo -e "  📖 https://github.com/IntelRealSense/librealsense"
echo -e "  🌐 https://www.intelrealsense.com/sdk/"

echo -e "\n${YELLOW}⚠️  Важно:${NC}"
echo -e "  После установки может потребоваться перезагрузка для загрузки модуля ядра"
echo -e "  ${YELLOW}Перезагрузить систему сейчас? (y/n)${NC}"
read -r reboot_now
if [[ $reboot_now == "y" || $reboot_now == "Y" ]]; then
    print_info "Система будет перезагружена через 5 секунд..."
    sleep 5
    sudo reboot
else
    print_warning "Не забудьте перезагрузить систему позже для загрузки модуля ядра"
fi

echo -e "\n"