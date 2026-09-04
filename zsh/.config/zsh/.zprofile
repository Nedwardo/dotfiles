if [[ -z "${MANAGERPIDFDID:-}" ]] && uwsm check may-start -v >> /tmp/uwsm-maystart.log 2>&1; then
  uwsm start default
else
  echo "$(date): may-start failed (exit $?)" >> /tmp/uwsm-maystart.log
  uwsm check may-start >> /tmp/uwsm-maystart.log 2>&1
fi
