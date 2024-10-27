# Troubleshooting Guide

This document provides guidance on common issues and their resolutions when working with your SaltStack architecture. Below are some typical problems you may encounter, along with commands to help diagnose and fix them.

## Common Issues and Commands

| **Issue**                                   | **Description**                                                    | **Generic Command**                                          | **Specific Command**                                         |
|---------------------------------------------|--------------------------------------------------------------------|-------------------------------------------------------------|-------------------------------------------------------------|
| **Container Not Running**                   | One or more containers are not running as expected.               | `./docker-compose.sh ps`                                    | `./docker-compose.sh exec salt_master ps -ef`              |
| **Container Restarted Automatically**       | A container keeps restarting due to errors.                       | `./docker-compose.sh logs <container_name>`                 | `./docker-compose.sh logs salt_syndic1`                    |
| **Connectivity Issues**                     | Minions or syndics cannot connect to the master.                  | `./docker-compose.sh exec salt_master salt '*' test.ping`   | `./docker-compose.sh exec salt_syndic1 salt 'minion-id' test.ping` |
| **Salt Key Issues**                         | Minion keys are not accepted or show as "unknown".                | `./docker-compose.sh exec salt_master salt-key -L`          | `./docker-compose.sh exec salt_master salt-key -A <minion-id>` |
| **Version Mismatch**                        | Different versions of SaltStack components might cause issues.     | `./docker-compose.sh exec salt_master salt --versions-report`| `./docker-compose.sh exec salt_syndic1 salt --versions-report` |
| **Resource Usage Problems**                 | High CPU or memory usage affecting performance.                    | `./docker-compose.sh stats`                                  | `./docker-compose.sh exec salt_master top`                  |
| **Log Examination**                         | Check logs for errors or warnings.                                | `./docker-compose.sh logs <container_name>`                 | `./docker-compose.sh exec salt_syndic1 tail -n 50 /var/log/salt/syndic` |

### Notes:
- Replace `<container_name>` with the actual name of the container you wish to inspect.
- Replace `<minion-id>` with the actual ID of the minion you are troubleshooting.

This table provides a quick reference for diagnosing and resolving common issues within your SaltStack architecture using Docker Compose. If you encounter a problem not listed here, consider checking the official SaltStack documentation or seeking help from the community.

| **Action**                                                                                                 | **Command**                                                   | **Docker-Compose Command**                                   |
|------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------|-------------------------------------------------------------|
| Send a ping to all minions on the master                                                                   | `salt '*' test.ping`                                        | `./docker-compose.sh exec salt_master salt '*' test.ping`  |
| Get more information about the grains                                                                      | `salt '*' grains.get os`                                    | `./docker-compose.sh exec salt_master salt '*' grains.get os`|
| Check the status of the syndics using salt-run                                                             | `salt-run manage.status`                                     | `./docker-compose.sh exec salt_master salt-run manage.status`|
| Test communication with the syndics using a simple command                                                | `salt 'syndic-*' test.ping`                                 | `./docker-compose.sh exec salt_master salt 'syndic-*' test.ping`|
| View accepted keys, including those of the syndics                                                         | `salt-key -L`                                               | `./docker-compose.sh exec salt_master salt-key -L`          |
| Check the version of Salt on the syndics                                                                    | `salt 'syndic-*' test.version`                              | `./docker-compose.sh exec salt_master salt 'syndic-*' test.version`|
| **If the status on the master shows down for all syndics, check:**                                       |                                                               |                                                             |
| Verify that the salt_syndic service is running                                                              | `ps -ef | grep syndic`                                      | `./docker-compose.sh exec salt_syndic ps -ef | grep syndic`|
| Examine syndic logs for potential errors                                                                    | `tail -f /var/log/salt/syndic`                             | `./docker-compose.sh exec salt_syndic tail -f /var/log/salt/syndic`|
| Check syndic configuration in `/etc/salt/master`                                                           | `cat /etc/salt/master | grep syndic_master`                | `./docker-compose.sh exec salt_syndic cat /etc/salt/master | grep syndic_master`|
| Ensure that the syndic's minion is correctly configured                                                     | `cat /etc/salt/minion`                                     | `./docker-compose.sh exec salt_syndic cat /etc/salt/minion`|
| Verify that the minion ID matches what is expected by the master                                           |                                                               |                                                             |
| Test network connectivity between the syndic and the master                                                | `ping salt_master`                                          | `./docker-compose.sh exec salt_syndic ping salt_master`     |
| Check that necessary ports are open (usually 4505 and 4506)                                               | `netstat -tulpn | grep salt`                                | `./docker-compose.sh exec salt_syndic netstat -tulpn | grep salt`|
| Verify that the syndic's key has been accepted on the master                                               | `salt-key -L`                                              | `./docker-compose.sh exec salt_master salt-key -L`          |
| Run the syndic in debug mode for more information                                                           | `salt-syndic -l debug`                                     | `./docker-compose.sh exec salt_syndic salt-syndic -l debug` |
| Test connectivity between the syndic and master                                                             | `docker exec salt_syndic1 salt salt_master test.ping`      | `./docker-compose.sh exec salt_syndic1 salt salt_master test.ping`|
| Check status of supervisor processes for syndic (salt_master, salt_syndic, salt_minion)                   | `docker exec salt_syndic1 supervisordctl status`           | `./docker-compose.sh exec salt_syndic1 supervisordctl status`|