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
print_header "УСТАНОВКА ДРАЙВЕРОВ NVIDIA"

sleep 3

# Шаг 1: Проверка наличия устройств NVIDIA
print_info "Проверка наличия устройств NVIDIA..."
echo -e "${YELLOW}▶${NC} lspci | grep -i nvidia"
lspci | grep -i nvidia
NVIDIA_DEVICES=$?

echo -e "${YELLOW}▶${NC} lsmod | grep nvidia"
lsmod | grep nvidia
NVIDIA_MODULES=$?

if [ $NVIDIA_DEVICES -ne 0 ] && [ $NVIDIA_MODULES -ne 0 ]; then
    print_error "Устройства NVIDIA не обнаружены!"
    echo -e "${RED}Нет устройств NVIDIA в системе. Установка прервана.${NC}"
    exit 1
fi
print_success "Устройства NVIDIA обнаружены"
echo ""

# Шаг 2: Проверка уже установленных драйверов
if lsmod | grep -q nvidia; then
    print_warning "Обнаружены установленные драйверы NVIDIA"
    echo -e "${YELLOW}Хотите удалить существующие драйверы и продолжить установку?${NC}"
    echo -e "  ${GREEN}y${NC} - удалить и установить заново"
    echo -e "  ${RED}n${NC} - оставить текущие драйверы и выйти"
    read -r remove_driver
    if [[ $remove_driver == "y" || $remove_driver == "Y" ]]; then
        print_info "Удаление существующих драйверов NVIDIA..."
        run_cmd "sudo apt remove --purge nvidia-* -y"
        print_success "Драйверы удалены"
    else
        print_info "Установка отменена пользователем"
        exit 0
    fi
else
    print_info "Существующие драйверы NVIDIA не обнаружены"
fi
echo ""

# Шаг 3: Обновление системы и добавление репозиториев
print_info "Обновление системы..."
run_cmd "sudo apt update && sudo apt upgrade -y"

print_info "Добавление репозиториев restricted и multiverse..."
run_cmd "sudo add-apt-repository restricted -y"
run_cmd "sudo add-apt-repository multiverse -y"
run_cmd "sudo apt update"

print_info "Установка build-essential и заголовков ядра..."
run_cmd "uname -r"
run_cmd "sudo apt install build-essential linux-headers-$(uname -r) -y"

print_info "Добавление PPA graphics-drivers..."
run_cmd "sudo add-apt-repository ppa:graphics-drivers/ppa -y"
run_cmd "sudo apt update"

# Шаг 4: Вывод списка доступных драйверов
print_header "ДОСТУПНЫЕ ДРАЙВЕРЫ NVIDIA"
echo -e "${CYAN}Список рекомендуемых драйверов:${NC}\n"
ubuntu-drivers devices
echo ""

# Шаг 5: Выбор версии драйвера
print_info "Введите номер версии драйвера (например, 570, 550, 535 и т.д.):"
echo -e "${YELLOW}Версия: ${NC}"
read -r driver_version

if [[ -z "$driver_version" ]]; then
    print_error "Версия драйвера не указана"
    exit 1
fi

# Проверка, что введено число
if ! [[ "$driver_version" =~ ^[0-9]+$ ]]; then
    print_error "Неверный формат. Введите только число (например, 570)"
    exit 1
fi

print_info "Установка драйвера nvidia-driver-${driver_version}..."
run_cmd "sudo apt install nvidia-driver-${driver_version} -y"

if [ $? -eq 0 ]; then
    print_success "Драйвер nvidia-driver-${driver_version} успешно установлен!"

    # Шаг 6: Предложение перезагрузить систему
    echo -e "\n${YELLOW}Для применения драйверов требуется перезагрузка системы.${NC}"
    echo -e "Перезагрузить сейчас? (y/n)"
    read -r reboot_now
    if [[ $reboot_now == "y" || $reboot_now == "Y" ]]; then
        print_info "Система будет перезагружена через 5 секунд..."
        sleep 5
        sudo reboot
    else
        print_warning "Не забудьте перезагрузить систему позже для применения драйверов"
    fi
else
    print_error "Ошибка при установке драйвера nvidia-driver-${driver_version}"
    exit 1
fi

echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}         УСТАНОВКА ДРАЙВЕРОВ NVIDIA ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "\n${CYAN}После перезагрузки проверьте установку командой:${NC}"
echo -e "  nvidia-smi"
echo -e "\n"