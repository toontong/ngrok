关于 ngrok 使用上的注意事项：
----
穿透利器 ngrok <https://github.com/inconshreveable/ngrok>


0x01 编译-多平台+要证书。
===
使用go语言，可以编译raspberry-pi 上运行的client端。
只需要修改下源Makefile， 在client前面加了GOOS="linux" GOARCH="arm"即可。

ngrok与ngrokd之间通过tls连接保证安全。自编译时需要生成证书：

		git clone https://github.com/inconshreveable/ngrok.git
		export GOPATH=/usr/local/src/ngrok/
		export NGROK_DOMAIN="domain.info"
		cd ngrok
		openssl genrsa -out rootCA.key 2048
		openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
		openssl genrsa -out device.key 2048
		openssl req -new -key device.key -subj "/CN=$NGROK_DOMAIN" -out device.csr
		openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
		cp rootCA.pem assets/client/tls/ngrokroot.crt -f
		cp device.crt assets/server/tls/snakeoil.crt -f
		cp device.key assets/server/tls/snakeoil.key -f
	
		GOOS=linux GOARCH=amd64 make release-server
	
		GOOS=linux GOARCH=arm   make release-client

服务端ngrokd 进程:
===
关于启动参数：

	./ngrokd -h
	Usage of ./ngrokd:
	  -domain="ngrok.com": Domain where the tunnels are hosted
	  -httpAddr=":80": Public address for HTTP connections, empty string to disable
	  -httpsAddr=":443": Public address listening for HTTPS connections, emptry string to disable
	  -log="stdout": Write log messages to this file. 'stdout' and 'none' have special meanings
	  -log-level="DEBUG": The level of messages to log. One of: DEBUG, INFO, WARNING, ERROR
	  -tlsCrt="": Path to a TLS certificate file
	  -tlsKey="": Path to a TLS key file
	  -tunnelAddr=":4443": Public address listening for ngrok client

这里搞不懂它可以指定tls证书启动，但编译时又要加入编译。

注意：

	1.它能额外监听了一个端口，基于web的管理功能。要使用netstat之类的命令查看，或看log输出--我还没找到启动参数。

	2.这里还得注意，它启动域名，使用一级域名。 当client端使用http/https连接上来，
		会分配一个2级域名给client作为client的入口; 但如果使用tcp协议，就不会分配2级域名，改为监控一个随机端口。

	3. 由于要穿透tcp协议时，服务端随机开端口。但连接断开后，所以利用起来，也比较麻烦。

客户端ngrok 进程
===
先看启动参数：

	./ngrok -h
	Usage: ./ngrok [OPTIONS] <local port or address>
	Options:
	  -authtoken="": Authentication token for identifying an ngrok.com account
	  -config="": Path to ngrok configuration file. (default: $HOME/.ngrok)
	  -hostname="": Request a custom hostname from the ngrok server. (HTTP only) (requires CNAME of your DNS)
	  -httpauth="": username:password HTTP basic auth creds protecting the public tunnel endpoint
	  -log="none": Write log messages to this file. 'stdout' and 'none' have special meanings
	  -log-level="DEBUG": The level of messages to log. One of: DEBUG, INFO, WARNING, ERROR
	  -proto="http+https": The protocol of the traffic over the tunnel {'http', 'https', 'tcp'} (default: 'http+https')
	  -subdomain="": Request a custom subdomain from the ngrok server. (HTTP only)

	Examples:
		ngrok 80
		ngrok -subdomain=example 8080
		ngrok -proto=tcp 22
		ngrok -hostname="example.com" -httpauth="user:password" 10.0.0.1

	Advanced usage: ngrok [OPTIONS] <command> [command args] [...]
	Commands:
		ngrok start [tunnel] [...]    Start tunnels by name from config file
		ngrok list                    List tunnel names from config file
		ngrok help                    Print help
		ngrok version                 Print ngrok version

	Examples:
		ngrok start www api blog pubsub
		ngrok -log=stdout -config=ngrok.yml start ssh
		ngrok version

协议上可以看到支持3种：http、https、tcp.

启动方式除了直接命令行参数外，还支持配置文件yml格式，形如：

	server_addr: domain.info:4443
	trust_host_root_certs: false
	#auth_token: aUvBfN7cXBGzBBcQa4hi
	tunnels:
	  myhttp:
	    auth: "user:psw123"
	    proto:
	      http: 10.20.134.198:80

	  ssh:
	    proto:
	      tcp: 22

注意项：

	0. 使用http/https连接上来，会分配一个2级域名给t的入口,如 myhttp.domain.info

	1. 使用tcp协议穿透，就不会分配2级域名，改为监控一个随机端口,如 domain.info:6789

就酱紫
