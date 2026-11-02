# zabbix-installer

Ubuntu 24.04 ortamında Zabbix 7.2 kurulumunu otomatikleştiren interaktif shell scriptleri.

## Gereksinimler

- Ubuntu LTS 24.04
- root yetkisi
- İnternet erişimi

## Sunucu kurulumu

Zabbix 7.2 + MySQL + Apache kurulumu:

```bash
sudo bash zabbix-install.sh
```

Yaptıkları:

- Resmi Zabbix deposunu ekler
- MySQL, Zabbix server, frontend ve agent paketlerini kurar
- MySQL veritabanını ve kullanıcısını oluşturur
- Zabbix şemasını içe aktarır
- Sunucu, frontend ve PHP yapılandırmalarını yazar
- Servisleri başlatır ve kalıcı olarak etkinleştirir

Varsayılan giriş bilgileri:

- Frontend: `http://SUNUCU_IP/zabbix`
- Kullanıcı: `Admin`
- Parola: `zabbix` (ilk girişte değiştirin)

## Agent kurulumu

Uzak sunuculara Zabbix Agent 2 kurulumu:

```bash
sudo bash zabbix-agent-install.sh
```

Yaptıkları:

- Resmi Zabbix deposunu ekler
- `zabbix-agent2` paketini kurar
- `Server`, `ServerActive` ve `Hostname` değerlerini yazar
- Servisi başlatır ve kalıcı olarak etkinleştirir

Script çalışırken Zabbix sunucu IP adresini ister; hostname boş geçilirse sistem hostname'i kullanılır.
