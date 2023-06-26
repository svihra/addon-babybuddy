#!/command/with-contenv bashio

mkdir -p /config/{data,media}
rm -rf /app/babybuddy/{data,media}
#ln -s /config/data /app/babybuddy/data
#ln -s /config/media /app/babybuddy/media

mkdir -p /data/{data,media}
ln -s /data/data /config/data
ln -s /data/data /app/babybuddy/data
ln -s /data/media /config/media
ln -s /data/media /app/babybuddy/media
#TODO: need to properly link  /config/.secretkey

cd /app/babybuddy
if [ ! -f "/config/.secretkey" ]; then
    echo "**** No secret key found, generating one ****"
    python3 manage.py shell -c 'from django.core.management import utils; print(utils.get_random_secret_key())' \
        | tr -d '\n' > /config/.secretkey
fi
export \
    DJANGO_SETTINGS_MODULE="babybuddy.settings.base" \
    ALLOWED_HOSTS="${ALLOWED_HOSTS:-*}" \
    TIME_ZONE="${TZ:-UTC}" \
    DEBUG="${DEBUG:-False}" \
    SECRET_KEY="${SECRET_KEY:-`cat /config/.secretkey`}"

bashio::log.info 'Checking for DB setup'
if bashio::config.has_value "DB_HOST"; then
    bashio::log.info 'Running with user defined database'
    export \
        DB_ENGINE=$(bashio::config "DB_ENGINE") \
        DB_HOST=$(bashio::config "DB_HOST") \
        DB_NAME=$(bashio::config "DB_NAME") \
        DB_PASSWORD=$(bashio::config "DB_PASSWORD") \
        DB_PORT=$(bashio::config "DB_PORT") \
        DB_USER=$(bashio::config "DB_USER")
fi
python3 manage.py migrate --noinput 
python3 manage.py createcachetable

chown -R root:root \
    /config
