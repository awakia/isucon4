# isucon4
Isuconの練習

## Prepare repository

```bash
# .ssh/config に isucon4 プロファイルを設定しておく
$ scp -r isucon4:/webapps .
$ mkdir -p config/etc
$ cd config/etc
$ scp isucon4:/etc/my.cnf .
```

## Service Restart Command
```
 $ sudo supervisorctl restart isucon_ruby
```
