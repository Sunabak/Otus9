#!/bin/bash
# Путь к лог-файлу
LOG_FILE="/root/log.log"
# Путь к временному файлу блокировки
LOCK_FILE="/tmp/analyze_log.lock"
# Путь для сохранения переменных
RESULT_DIR="/root/rez/"
# Проверка наличия блокировочного файла и завершение, если он уже существует
if [ -e "$LOCK_FILE" ]; then
  echo "Script is already running. Exiting."
  exit 1
fi
# Создание блокировочного файла
touch "$LOCK_FILE"
# Получение номера строки попавшей в отчет
LAST_RUN=$(cat "$RESULT_DIR/last_runNR" 2>/dev/null)
LAST_RUN=$((LAST_RUN + 1))
# Получение даты последнего запуска скрипта
LAST_RUNTIME=$(cat "$RESULT_DIR/last_run" 2>/dev/null)
# Формирование отчета
MAIL_CONTENT=""
# Список IP адресов с наибольшим количеством запросов
IP_LIST=$(awk -v last_run="$LAST_RUN" 'NR > last_run {print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr)
MAIL_CONTENT+="\n\nСписок IP адресов (с наибольшим кол-вом запросов):\n$IP_LIST"
# Список URL с наибольшим количеством запросов
URL_LIST=$(awk -v last_run="$LAST_RUN" 'NR > last_run {print $11}' "$LOG_FILE" | sort | uniq -c | sort -nr)
MAIL_CONTENT+="\n\nСписок запрашиваемых URL (с наибольшим кол-вом запросов):\n$URL_LIST"
# Ошибки веб-сервера/приложения
ERRORS=$(awk -v last_run="$LAST_RUN" 'NR > last_run {print $9}' "$LOG_FILE" | grep -Eo "[4][0-9][0-9]" | sort | uniq -c | sort -nr)
#(grep -Eo "\" [45][0-9][0-9] " "$LOG_FILE" | sort | uniq -c | sort -nr | awk -v last_run="$LAST_RUN" '$2 > last_run {print $2, $1}')
MAIL_CONTENT+="\n\nОшибки веб-сервера/приложения:\n$ERRORS"
# Список всех кодов HTTP ответа
HTTP_CODES=$(awk -v last_run="$LAST_RUN" 'NR > last_run {print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr)
MAIL_CONTENT+="\n\nСписок всех кодов HTTP ответа:\n$HTTP_CODES"
# Временной диапазон
MAIL_CONTENT+="\n\nВременной диапазон: с $LAST_RUNTIME до $(date +'%Y-%m-%d %H:%M:%S')"
# Отправка письма на заданную почту, адрес рандомный
echo -e "$MAIL_CONTENT" | mail -s "your_email@example.com"
# Обновление временной метки последнего запуска скрипта
date +'%Y-%m-%d %H:%M:%S' > "$RESULT_DIR/last_run"
wc -l < "$LOG_FILE" > "$RESULT_DIR/last_runNR"
# Удаление блокировочного файла
rm "$LOCK_FILE"