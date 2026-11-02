# zabbix-installer

Ubuntu 24.04 sunucusunda Zabbix 7.2 + MySQL + Apache kurulumunu otomatikleştiren interaktif shell scripti.

## Gereksinimler

- Ubuntu LTS 24.04
- root yetkisi
- İnternet erişimi

## Kullanım

```bash
sudo bash zabbix-install.sh
```

## Ne yapar

- Resmi Zabbix deposunu ekler
- MySQL, Zabbix server, frontend ve agent paketlerini kurar
- MySQL veritabanını ve kullanıcısını oluşturur
- Zabbix şemasını içe aktarır
- Sunucu, frontend ve PHP yapılandırmalarını yazar
- Servisleri başlatır ve kalıcı olarak etkinleştirir

## Varsayılan giriş bilgileri

- Frontend: `http://SUNUCU_IP/zabbix`
- Kullanıcı: `Admin`
- Parola: `zabbix` (ilk girişte değiştirin)
