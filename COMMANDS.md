
Sur le master, envoi d'un ping sur tous les minions
salt '*' test.ping

Plus d'infos sur les grains
salt '*' grains.get os

Utilisez la commande salt-run pour vérifier l'état des syndics :
salt-run manage.status

tester la communication avec les syndics en exécutant une commande simple comme :
salt 'syndic-*' test.ping

Pour voir les clés acceptées, y compris celles des syndics :
salt-key -L

vérifier la version de Salt sur les syndics :
salt 'syndic-*' test.version

Que vérifier dans le syndic si le résultat du status dans le master est down pour tous les syndics ?

Vérifiez que le service salt-syndic est en cours d'exécution :
ps -ef |grep syndic

Examinez les logs du syndic pour détecter d'éventuelles erreurs :
tail -f /var/log/salt/syndic

Vérifiez la configuration du syndic dans /etc/salt/master :
cat /etc/salt/master | grep syndic_master

Vérifiez que le minion du syndic est correctement configuré 
cat /etc/salt/minion

Assurez-vous que l'ID du minion correspond à celui attendu par le master.

Testez la connectivité réseau entre le syndic et le master :
ping salt_master

Vérifiez que les ports nécessaires sont ouverts (généralement 4505 et 4506) :
netstat -tulpn | grep salt

Vérifiez que la clé du syndic a bien été acceptée sur le master principal :
salt-key -L

Exécutez le syndic en mode debug pour obtenir plus d'informations :
salt-syndic -l debug



