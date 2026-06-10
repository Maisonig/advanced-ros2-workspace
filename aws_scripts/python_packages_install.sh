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

# Получаем директорию, где находится скрипт
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Поднимаемся на один уровень вверх (из aws_scripts в src)
SRC_DIR="$(dirname "$SCRIPT_DIR")"
REQUIREMENTS_FILE="$SRC_DIR/requirements.txt"

clear
print_header "УСТАНОВКА PYTHON ЗАВИСИМОСТЕЙ"

# Шаг 1: Проверка, находимся ли мы в виртуальном окружении
print_info "Проверка активного виртуального окружения..."

if [[ -z "$VIRTUAL_ENV" ]]; then
    print_error "Вы не находитесь в виртуальном окружении!"
    echo -e "\n${YELLOW}Пожалуйста, активируйте виртуальное окружение:${NC}"
    echo -e "  ${CYAN}source /path/to/your/venv/bin/activate${NC}"
    echo -e "\n${YELLOW}Или используйте скрипт для создания окружения:${NC}"
    echo -e "  ${CYAN}./setup_ros_venv.sh${NC}"
    echo -e "\n${RED}Установка зависимостей прервана.${NC}"
    exit 1
else
    print_success "Обнаружено виртуальное окружение: $VIRTUAL_ENV"
fi

# Шаг 2: Проверка наличия pip в окружении
print_info "Проверка наличия pip..."
if ! command -v pip &> /dev/null; then
    print_error "pip не найден в виртуальном окружении"
    print_info "Установка pip..."
    run_cmd "python3 -m ensurepip --upgrade"
fi
print_success "pip доступен: $(pip --version)"

# Шаг 3: Проверка существования requirements.txt
print_info "Поиск файла requirements.txt..."
print_info "Путь к скрипту: $SCRIPT_DIR"
print_info "Директория src: $SRC_DIR"
print_info "Ожидаемый путь к requirements.txt: $REQUIREMENTS_FILE"

if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
    print_error "Файл requirements.txt не найден по пути: $REQUIREMENTS_FILE"
    echo -e "\n${YELLOW}Проверьте, что файл requirements.txt существует в директории:${NC}"
    echo -e "  ${CYAN}$SRC_DIR/${NC}"
    echo -e "\n${YELLOW}Структура директорий должна быть такой:${NC}"
    echo -e "  ${CYAN}$SRC_DIR/${NC}"
    echo -e "  ${CYAN}$SRC_DIR/aws_scripts/${NC}"
    echo -e "  ${CYAN}$SRC_DIR/aws_scripts/$(basename "$0")${NC}"
    exit 1
fi
print_success "Файл requirements.txt найден: $REQUIREMENTS_FILE"

# Шаг 4: Обновление pip
print_info "Обновление pip до последней версии..."
run_cmd "pip install --upgrade pip"

# Шаг 5: Установка зависимостей
print_info "Установка зависимостей из requirements.txt..."
echo -e "${YELLOW}▶${NC} pip install -r \"$REQUIREMENTS_FILE\""
pip install -r "$REQUIREMENTS_FILE"

if [ $? -eq 0 ]; then
    print_success "Все зависимости успешно установлены"
else
    print_error "Ошибка при установке зависимостей"
    echo -e "\n${YELLOW}Возможные решения:${NC}"
    echo -e "  1. Проверьте интернет-соединение"
    echo -e "  2. Проверьте синтаксис в requirements.txt"
    echo -e "  3. Установите зависимости по отдельности"
    exit 1
fi

# Шаг 6: Показ установленных пакетов (опционально)
echo -e "\n${YELLOW}Показать список установленных пакетов? (y/n)${NC}"
read -r show_packages
if [[ $show_packages == "y" || $show_packages == "Y" ]]; then
    print_info "Установленные пакеты:"
    pip list
fi

# Финальные инструкции
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}         УСТАНОВКА ЗАВИСИМОСТЕЙ ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Проверка установленных зависимостей:${NC}"
echo -e "  ${YELLOW}pip list${NC}"
echo -e "  ${YELLOW}pip show <package_name>${NC}"

echo -e "\n${CYAN}Для экспорта зависимостей в файл:${NC}"
echo -e "  ${YELLOW}pip freeze > requirements.txt${NC}"
echo -e "\n"