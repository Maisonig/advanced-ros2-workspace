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

# Получаем директорию, где находится скрипт
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Путь к файлу ros2_requirements.txt (на уровень выше из aws_scripts в src)
REQUIREMENTS_FILE="$SCRIPT_DIR/../ros2_requirements.txt"

# Главная установка
clear
print_header "УСТАНОВКА ROS2 ПАКЕТОВ ИЗ requirements.txt"

print_info "Директория скрипта: $SCRIPT_DIR"
print_info "Путь к requirements: $REQUIREMENTS_FILE"

# Шаг 1: Проверка существования файла requirements
if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
    print_error "Файл ros2_requirements.txt не найден!"
    print_info "Ожидаемый путь: $REQUIREMENTS_FILE"
    print_info "Структура директорий должна быть:"
    echo -e "  ${CYAN}src/${NC}"
    echo -e "  ${CYAN}├── ros2_requirements.txt${NC}"
    echo -e "  ${CYAN}└── aws_scripts/${NC}"
    echo -e "  ${CYAN}    └── $(basename "$0")${NC}"
    exit 1
fi

print_success "Файл найден: $(basename "$REQUIREMENTS_FILE")"

# Шаг 2: Чтение и установка пакетов
print_info "Чтение списка пакетов..."

# Массив для хранения пакетов
declare -a packages
line_number=0

# Читаем файл построчно, игнорируя пустые строки и комментарии
while IFS= read -r line || [ -n "$line" ]; do
    line_number=$((line_number + 1))
    
    # Удаляем пробелы в начале и конце
    package=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    # Пропускаем пустые строки и комментарии (начинающиеся с #)
    if [[ -z "$package" ]] || [[ "$package" =~ ^# ]]; then
        continue
    fi
    
    # Заменяем переменную ROS_DISTRO в имени пакета
    package=$(echo "$package" | sed "s/\$ROS_DISTRO/$ROS_DISTRO/g")
    
    packages+=("$package")
    print_info "Найден пакет: $package"
    
done < "$REQUIREMENTS_FILE"

if [ ${#packages[@]} -eq 0 ]; then
    print_error "В файле ros2_requirements.txt нет пакетов для установки"
    print_info "Добавьте пакеты в файл (по одному на строку)"
    exit 1
fi

echo ""
print_header "НАЙДЕНО ПАКЕТОВ: ${#packages[@]}"

# Шаг 3: Обновление списка пакетов
print_info "Обновление списка пакетов apt..."
run_cmd "sudo apt update"

# Шаг 4: Установка каждого пакета
print_info "Установка пакетов..."

successful=0
failed=0
failed_packages=()

for package in "${packages[@]}"; do
    print_info "Установка: $package"
    run_cmd "sudo apt install -y $package"
    
    if [ $? -eq 0 ]; then
        successful=$((successful + 1))
    else
        failed=$((failed + 1))
        failed_packages+=("$package")
    fi
done

# Шаг 5: Итоговый отчет
echo ""
print_header "РЕЗУЛЬТАТ УСТАНОВКИ"

echo -e "${CYAN}✅ Успешно установлено: ${GREEN}$successful${NC}"
echo -e "${CYAN}❌ Не удалось установить: ${RED}$failed${NC}"

if [ $failed -gt 0 ]; then
    echo -e "\n${YELLOW}Список пакетов, которые не удалось установить:${NC}"
    for pkg in "${failed_packages[@]}"; do
        echo -e "  ${RED}✗ $pkg${NC}"
    done
    
    echo -e "\n${CYAN}Возможные причины:${NC}"
    echo -e "  • Неправильное имя пакета"
    echo -e "  • Пакет не доступен для вашей версии ROS ($ROS_DISTRO)"
    echo -e "  • Пакет требует другой версии Ubuntu"
    echo -e "\n${YELLOW}Попробуйте установить проблемные пакеты вручную:${NC}"
    for pkg in "${failed_packages[@]}"; do
        echo -e "  ${YELLOW}sudo apt install $pkg${NC}"
    done
fi

# Шаг 6: Проверка установленных пакетов (опционально)
echo -e "\n${YELLOW}Показать список установленных ROS пакетов? (y/n)${NC}"
read -r show_packages
if [[ $show_packages == "y" || $show_packages == "Y" ]]; then
    print_info "Установленные ROS пакеты:"
    dpkg -l | grep -E "ros-$ROS_DISTRO" | awk '{print $2}' | sort
fi

# Финальная информация
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}         УСТАНОВКА ROS2 ПАКЕТОВ ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Информация:${NC}"
echo -e "  📄 Файл требований: ${GREEN}$REQUIREMENTS_FILE${NC}"
echo -e "  📦 Установлено пакетов: ${GREEN}$successful${NC}"
if [ $failed -gt 0 ]; then
    echo -e "  ❌ Не установлено: ${RED}$failed${NC}"
fi

echo -e "\n${CYAN}Для добавления новых пакетов:${NC}"
echo -e "  Отредактируйте файл: ${YELLOW}nano $REQUIREMENTS_FILE${NC}"
echo -e "  Добавьте новые пакеты (по одному на строку)"
echo -e "  Затем запустите скрипт снова"

echo -e "\n${CYAN}Пример добавления пакетов:${NC}"
echo -e "  ${YELLOW}ros-$ROS_DISTRO-tf2${NC}"
echo -e "  ${YELLOW}ros-$ROS_DISTRO-rviz2${NC}"
echo -e "  ${YELLOW}ros-$ROS_DISTRO-gazebo-ros-pkgs${NC}"

echo -e "\n"