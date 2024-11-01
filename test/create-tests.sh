#!/bin/bash

mkdir -p test_json_files && cd test_json_files

cat << EOF > check_salt_ms_communication_syndic_configuration.json
{
    "command": "./docker-compose.sh exec salt_syndic1 cat /etc/salt/master | grep syndic_master",
    "path": "./",
    "expected_return_type": "output_message",
    "expected_value": "syndic_master",
    "timeout": 1000,
    "description": "Check syndic configuration: Check if syndic_master is correctly set to the master's address."
}
EOF

cat << EOF > check_salt_ms_communication_master_configuration.json
{
    "command": "./docker-compose.sh exec salt_master cat /etc/salt/master | grep order_masters",
    "path": "./",
    "expected_return_type": "output_message",
    "expected_value": "order_masters: True",
    "timeout": 1000,
    "description": "Check master configuration: Ensure that order_masters is set to True on the master."
}
EOF

cat << EOF > check_salt_ms_communication_key_acceptance.json
{
    "command": "./docker-compose.sh exec salt_master salt-key -L",
    "path": "./",
    "expected_return_type": "output_message",
    "expected_value": "<syndics_key>",
    "timeout": 1000,
    "description": "Check key acceptance: Check if the syndic's key is in the 'Accepted Keys' list."
}
EOF

cat << EOF > check_salt_ms_communication_basic_salt_communication.json
{
    "command": "./docker-compose.sh exec salt_syndic1 salt-call test.ping",
    "path": "./",
    "expected_return_type": "return_code",
    "expected_value": 0,
    "timeout": 1000,
    "description": "Check basic Salt communication: This should return True if Salt is functioning correctly on the syndic."
}
EOF

cat << EOF > check_salt_ms_communication_syndic_logs.json
{
    "command": "./docker-compose.sh exec salt_syndic1 tail -f /var/log/salt/syndic",
    "path": "./",
    "expected_return_type": "return_code",
    "expected_value": 0,
    "timeout": 1000,
    "description": "Check syndic logs for more detailed error messages."
}
EOF

cat << EOF > check_salt_ms_communication_master_logs.json
{
    "command": "./docker-compose.sh exec salt_master tail -f /var/log/salt/master",
    "path": "./",
    "expected_return_type": "return_code",
    "expected_value": 0,
    "timeout": 1000,
    "description": "Check master logs for any related errors."
}
EOF

cat << EOF > check_salt_ms_communication_ports_open.json
{
    "command": "./docker-compose.sh exec salt_master netstat -tulpn | grep salt",
    "path": "./",
    "expected_return_type": "output_message",
    "expected_value": "",
    "timeout": 1000,
    "description": "Check that the necessary ports (typically 4505 and 4506) are open."
}
EOF

cat << EOF > check_salt_ms_communication_restart_syndic_service.json
{
    "command": "./docker-compose.sh exec salt_syndic1 supervisorctl restart salt-syndic && ./docker-compose.sh exec salt_syndic1 tail -f /var/log/salt/syndic",
    "path": "./",
    "expected_return_type": "return_code",
    "expected_value": 0,
    "timeout": 1000,
    "description": "Restart the syndic service and check for any startup errors."
}
EOF

cat << EOF > check_salt_ms_communication_establish_connection.json
{
    "command": "./docker-compose.sh exec salt_syndic1 salt-syndic -d",
    "path": "./",
    "expected_return_type": "return_code",
    "expected_value": 0,
    "timeout": 1000,
    "description": "Establish a connection from the syndic to the master manually."
}
EOF