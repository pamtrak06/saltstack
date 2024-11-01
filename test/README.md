Based on the error message "Unable to call _fire_master on salt_master, that syndic is not connected", here are some tests you can run to verify the communication between the syndic and master:
Check network connectivity:
text
./docker-compose.sh exec salt_syndic1 ping salt_master

This will verify if the syndic can reach the master.
Verify syndic configuration:
text
./docker-compose.sh exec salt_syndic1 cat /etc/salt/master | grep syndic_master

Ensure that syndic_master is correctly set to the master's address.
Check master configuration:
text
./docker-compose.sh exec salt_master cat /etc/salt/master | grep order_masters

Verify that order_masters is set to True on the master.
Verify key acceptance:
text
./docker-compose.sh exec salt_master salt-key -L

Check if the syndic's key is in the "Accepted Keys" list.
Test basic Salt communication:
text
./docker-compose.sh exec salt_syndic1 salt-call test.ping

This should return True if Salt is functioning correctly on the syndic.
Check syndic logs for more detailed error messages:
text
./docker-compose.sh exec salt_syndic1 tail -f /var/log/salt/syndic

Check master logs for any related errors:
text
./docker-compose.sh exec salt_master tail -f /var/log/salt/master

Verify that the necessary ports (typically 4505 and 4506) are open:
text
./docker-compose.sh exec salt_master netstat -tulpn | grep salt

Restart the syndic service and check for any startup errors:
text
./docker-compose.sh exec salt_syndic1 supervisorctl restart salt-syndic
./docker-compose.sh exec salt_syndic1 tail -f /var/log/salt/syndic

Try to establish a connection from the syndic to the master manually:
text
./docker-compose.sh exec salt_syndic1 salt-syndic -d

This will run the syndic daemon in debug mode, which may provide more information about the connection issue.
These tests should help identify where the communication breakdown is occurring between the syndic and the master.