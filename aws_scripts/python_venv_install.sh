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

# Функция для генерации уникального имени функции
generate_unique_func_name() {
    local base_name="activate_ros_venv"
    local counter=1
    local func_name="${base_name}"

    # Проверяем существование функции в текущей сессии и в .bashrc
    while grep -q "^${func_name}()" ~/.bashrc 2>/dev/null || declare -f "$func_name" >/dev/null 2>&1; do
        counter=$((counter + 1))
        func_name="${base_name}${counter}"
    done

    echo "$func_name"
}

# Главная установка
clear
print_header "ПОДГОТОВКА ВИРТУАЛЬНОГО ОКРУЖЕНИЯ ROS2"

# Шаг 1: Установка python3-venv
print_info "Установка python3-venv..."
run_cmd "sudo apt install python3-venv -y"

# Шаг 2: Ввод пути до рабочей области
echo -e "${CYAN}ℹ${NC} Введите полный путь до рабочей области ROS2"
echo -e "${YELLOW}Пример: /home/$(whoami)/dev_ws${NC}"
echo -e "${YELLOW}Путь: ${NC}"
read -r workspace_path

# Проверка, что путь не пустой
if [[ -z "$workspace_path" ]]; then
    print_error "Путь не может быть пустым"
    exit 1
fi

# Проверка, существует ли директория
if [[ ! -d "$workspace_path" ]]; then
    print_warning "Директория $workspace_path не существует"
    echo -e "${YELLOW}Создать директорию? (y/n)${NC}"
    read -r create_dir
    if [[ $create_dir == "y" || $create_dir == "Y" ]]; then
        run_cmd "mkdir -p $workspace_path"
        print_success "Директория создана: $workspace_path"
    else
        print_error "Установка прервана"
        exit 1
    fi
fi

# Шаг 3: Переход в рабочую область
print_info "Переход в рабочую область: $workspace_path"
run_cmd "cd $workspace_path"
cd "$workspace_path" || { print_error "Не удалось перейти в $workspace_path"; exit 1; }
print_success "Текущая директория: $(pwd)"

# Шаг 4: Создание виртуального окружения с --system-site-packages
if [[ -d "venv" ]]; then
    print_warning "Виртуальное окружение 'venv' уже существует"
    echo -e "${YELLOW}Пересоздать окружение? (y/n)${NC}"
    read -r recreate
    if [[ $recreate == "y" || $recreate == "Y" ]]; then
        print_info "Удаление старого окружения..."
        run_cmd "rm -rf venv"
        print_info "Создание нового виртуального окружения с доступом к системным пакетам..."
        run_cmd "python3 -m venv --system-site-packages venv"
    else
        print_info "Используем существующее окружение"
    fi
else
    print_info "Создание виртуального окружения 'venv' с доступом к системным пакетам..."
    run_cmd "python3 -m venv --system-site-packages venv"
fi

# Шаг 5: Активация виртуального окружения
print_info "Активация виртуального окружения..."
source venv/bin/activate
if [[ "$VIRTUAL_ENV" != "" ]]; then
    print_success "Виртуальное окружение активировано: $VIRTUAL_ENV"
else
    print_error "Не удалось активировать виртуальное окружение"
    exit 1
fi

# Определение версии Python
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
print_info "Версия Python: $PYTHON_VERSION"

# Шаг 6: Создание символических ссылок на пакеты ROS2
print_info "Создание символических ссылок на пакеты ROS2..."

# Проверка существования директории ROS2
ROS2_SITE_PACKAGES="/opt/ros/jazzy/lib/python${PYTHON_VERSION}/site-packages"
if [[ ! -d "$ROS2_SITE_PACKAGES" ]]; then
    print_error "Директория ROS2 не найдена: $ROS2_SITE_PACKAGES"
    print_info "Проверьте, что ROS2 Jazzy установлен и версия Python совпадает"
    exit 1
fi

VENV_SITE_PACKAGES="venv/lib/python${PYTHON_VERSION}/site-packages"

# Создание символических ссылок
run_cmd "ln -sf $ROS2_SITE_PACKAGES/* $VENV_SITE_PACKAGES/ 2>/dev/null"
print_success "Символические ссылки созданы"

# Шаг 7: Проверка работоспособности
print_info "Проверка импорта ROS2 пакетов..."
python3 -c "import rclpy; print('rclpy version:', rclpy.__version__)" 2>/dev/null
if [ $? -eq 0 ]; then
    print_success "ROS2 пакеты успешно импортируются"
else
    print_warning "Не удалось импортировать rclpy, проверьте символические ссылки"
fi

# Дополнительная проверка catkin_pkg (частая причина падения colcon build)
python3 -c "import catkin_pkg; print('catkin_pkg version:', catkin_pkg.__version__)" 2>/dev/null
if [ $? -eq 0 ]; then
    print_success "catkin_pkg доступен"
else
    print_warning "catkin_pkg не найден — colcon build может упасть на aws_bringup"
    print_info "Попробуйте: sudo apt install python3-catkin-pkg"
fi

# Шаг 8: Добавление скрипта активации в .bashrc
echo -e "\n${YELLOW}Добавить скрипт для автоматической активации окружения при запуске терминала?${NC}"
echo -e "${CYAN}При каждом запуске терминала будет появляться предложение активировать окружение${NC}"
echo -e "${YELLOW}Добавить? (y/n, по умолчанию n): ${NC}"
read -r add_to_bashrc

if [[ $add_to_bashrc == "y" || $add_to_bashrc == "Y" ]]; then
    # Генерируем уникальное имя для функции
    UNIQUE_FUNC_NAME=$(generate_unique_func_name)
    print_info "Создана уникальная функция: ${UNIQUE_FUNC_NAME}"

    # Создаем функцию для .bashrc с уникальным именем и указанием пути
    BASHRC_FUNCTION="
# Функция для активации виртуального окружения ROS2 (рабочая область: $workspace_path)
${UNIQUE_FUNC_NAME}() {
    if [[ -f \"$workspace_path/venv/bin/activate\" ]]; then
        echo -e \"\\033[1;33mАктивировать виртуальное окружение $workspace_path/venv? (y/n)\\033[0m\"
        read -r should_activate
        if [[ \$should_activate == \"y\" || \$should_activate == \"Y\" ]]; then
            source \"$workspace_path/venv/bin/activate\"
            echo -e \"\\033[0;32m✓ Виртуальное окружение активировано: $workspace_path/venv\\033[0m\"
        fi
    fi
}

# Запуск проверки при каждом открытии терминала
${UNIQUE_FUNC_NAME}
"

    # Проверяем, не добавлена ли уже такая рабочая область
    if grep -q "source \"$workspace_path/venv/bin/activate\"" ~/.bashrc; then
        print_warning "Эта рабочая область уже добавлена в .bashrc"
        echo -e "${YELLOW}Пропускаем добавление, чтобы избежать дублирования${NC}"
    else
        echo "$BASHRC_FUNCTION" >> ~/.bashrc
        print_success "Скрипт добавлен в .bashrc с функцией ${UNIQUE_FUNC_NAME}"
        print_info "При следующем открытии терминала будет предложено активировать окружение"
        print_info "Сообщение будет выглядеть так:"
        echo -e "  ${YELLOW}Активировать виртуальное окружение $workspace_path/venv? (y/n)${NC}"

        # Показываем пользователю информацию о созданной функции
        echo -e "\n${CYAN}Информация о добавленной функции:${NC}"
        echo -e "  📝 Имя функции: ${GREEN}${UNIQUE_FUNC_NAME}${NC}"
        echo -e "  📁 Рабочая область: ${GREEN}$workspace_path${NC}"
    fi
else
    print_info "Скрипт не добавлен в .bashrc"
    print_info "Для ручной активации используйте: source $workspace_path/venv/bin/activate"
fi

# Финальные инструкции
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}      ПОДГОТОВКА ВИРТУАЛЬНОГО ОКРУЖЕНИЯ ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Итоговая информация:${NC}"
echo -e "  📁 Рабочая область: ${GREEN}$workspace_path${NC}"
echo -e "  🐍 Виртуальное окружение: ${GREEN}$workspace_path/venv${NC}"
echo -e "  🔗 Ссылки на ROS2: ${GREEN}созданы${NC}"

echo -e "\n${CYAN}Команды для ручной работы:${NC}"
echo -e "  Активация:       ${YELLOW}source $workspace_path/venv/bin/activate${NC}"
echo -e "  Деактивация:     ${YELLOW}deactivate${NC}"
echo -e "  Удалить окружение: ${YELLOW}rm -rf $workspace_path/venv${NC}"

echo -e "\n${CYAN}Проверка работы:${NC}"
echo -e "  source $workspace_path/venv/bin/activate"
echo -e "  python3 -c 'import rclpy; print(\"ROS2 работает!\")'"
echo -e "\n"