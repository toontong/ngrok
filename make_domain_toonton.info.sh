export NGROK_DOMAIN="toontong.info"


openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
openssl genrsa -out device.key 2048
openssl req -new -key device.key -subj "/CN=$NGROK_DOMAIN" -out device.csr
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
cp rootCA.pem assets/client/tls/ngrokroot.crt -f
cp device.crt assets/server/tls/snakeoil.crt -f
cp device.key assets/server/tls/snakeoil.key -f

GOOS=linux GOARCH=amd64
make release-server

GOOS=linux GOARCH=arm make release-client




