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

Test communication between syndics and master
- check if syndics can reach master through the network
    ```bash
    ./docker-compose.sh exec salt_syndic1 ping salt_master 
    ./docker-compose.sh exec salt_syndic2 ping salt_master
    ```
- check if syndics can ping master through salt command
    ```bash
    ./docker-compose.sh exec salt_syndic1 salt salt_master test.ping
    ./docker-compose.sh exec salt_syndic2 salt salt_master test.ping
    ```bash
- check if syndics keys are accepted from master
    ```bash
    ./docker-compose.sh exec salt_master salt-key -L
    ```
- accept syndics keys from master
    ```bash
    ./docker-compose.sh exec salt_master salt-key -A
    ```
- Ensure that the Salt services are running correctly on both the master and syndic.
    ```bash
    docker exec salt_syndic1 service salt-minion status
    docker exec salt_syndic2 service salt-minion status
    docker exec salt_syndic1 service salt-master status
    docker exec salt_syndic2 service salt-master status
    docker exec salt_syndic1 service salt-syndic status
    docker exec salt_syndic2 service salt-syndic status
    ```
- Check the logs for any errors or warnings that may indicate what is wrong. 
    ```bash
    docker exec salt_syndic1 tail -n 100 /var/log/salt/minion
    docker exec salt_syndic2 tail -n 100 /var/log/salt/minion
    ```
- Ensure that there are no firewall rules blocking communication between the syndic and master, especially on ports 4505 and 4506.
    ```bash
    docker exec salt_syndic1 netstat -tuln | grep 4505
    docker exec salt_syndic2 netstat -tuln | grep 4506
    ```
- Verify that the minion configuration file (/etc/salt/minion) on your syndic has the correct master address set
    ```bash
    docker exec -it salt_syndic1 cat /etc/salt/minion | grep master:
    docker exec -it salt_syndic2 cat /etc/salt/minion | grep master:
    ```bash


| **Action**                          | **Command**                                                |
|-------------------------------------|------------------------------------------------------------|
| Check minion connectivity           | `docker exec -it salt_syndic1 salt salt_master test.ping` |
| Verify key acceptance               | `./docker-compose.sh exec salt_master salt-key -L`        |
| Check service status                | `docker exec -it salt_syndic1 service salt-minion status` |
| Start service if not running        | `docker exec -it salt_syndic1 service salt-minion start`  |
| Inspect logs                        | `docker exec -it salt_syndic1 tail -n 100 /var/log/salt/minion` |
| Check firewall rules                | `sudo netstat -tuln | grep 4505`<br>`sudo netstat -tuln | grep 4506` |
| Restart services                    | `./docker-compose.sh restart`                              |
| Run in debug mode                   | `./docker-compose.sh exec salt_master salt-master -l debug`<br>`./docker-compose.sh exec salt_syndic1 salt-minion -l debug` |
| Check minion configuration          | `docker exec -it salt_syndic1 cat /etc/salt/minion | grep master:` |

Next Steps After Positive Command Results

| **Step**                     | **Description**                                                                                  | **Command**                                            |
|------------------------------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| **1. Validate Configuration** | Ensure that all configuration files for SaltStack components (master, syndic, minions) are correct and properly set up. | `./docker-compose.sh exec salt_master cat /etc/salt/master` |
| **2. Perform Functional Tests** | Execute functional tests to verify that each component behaves as expected under normal conditions. | `./docker-compose.sh exec salt_master salt '*' test.ping` |
| **3. Conduct End-to-End Tests** | Run end-to-end tests to simulate real user scenarios and ensure that the entire system works together seamlessly. | `./docker-compose.sh exec salt_master salt-call state.apply` |
| **4. Monitor Resource Usage** | Check CPU, memory, and disk usage on the master and other components to ensure they are operating within acceptable limits. | `./docker-compose.sh stats`                          |
| **5. Review Logs for Errors** | Examine logs for any warnings or errors that may not have caused failures but could indicate potential issues. | `./docker-compose.sh logs salt_master`                |
| **6. Verify Key Management** | Ensure that all minion keys are accepted and properly managed in the Salt master.               | `./docker-compose.sh exec salt_master salt-key -L`    |
| **7. Run Regression Tests**  | If changes were made or new features added, run regression tests to ensure existing functionality is not broken. | `./docker-compose.sh exec salt_master salt-run state.apply` |
| **8. Prepare for Production** | If all tests pass, prepare the system for production deployment, ensuring that documentation is updated accordingly. | N/A                                                   |


## Command Interpretation

### Command: `./docker-compose.sh exec salt_master salt '*' test.ping`

**Output:**
`No minions matched the target. No command was sent, no jid was assigned.`
`ERROR: No return received`

#### Interpretation:
- **No Minions Matched the Target**: This indicates that the Salt master did not find any minions that match the target specified (`*` means all minions). This could be due to several reasons:
  - The minions are not properly connected to the master.
  - The minion keys have not been accepted on the master.
  - The minion IDs do not match what the master expects.

- **No Command Was Sent, No JID Was Assigned**: Since no matching minions were found, no command was executed, and therefore, no Job ID (JID) was created for tracking.

### Next Steps:
1. **Check Minion Status**: Run `./docker-compose.sh exec salt_master salt-key -L` to see if any minion keys are listed as accepted.
2. **Verify Connectivity**: Ensure that your minions can reach the master and that they are running.
3. **Inspect Minion Configuration**: Check that each minion's configuration file (`/etc/salt/minion`) has the correct master address.

---

### Command: `./docker-compose.sh exec salt_master salt-call state.apply`

**Output:**
`[ERROR   ] DNS lookup or connection check of 'salt' failed.`
`[ERROR   ] Master hostname: 'salt' not found or not responsive. Retrying in 30 seconds`


#### Interpretation:
- **DNS Lookup or Connection Check Failed**: This error indicates that the Salt master cannot resolve the hostname salt. This could be due to misconfigured DNS settings or network issues.
- **Master Hostname Not Found or Not Responsive**: The Salt master is unable to connect to itself using the hostname specified. This can happen if:
    - The hostname is incorrectly configured in /etc/hosts or /etc/salt/master.
    - There are issues with DNS resolution on the system.

#### Next Steps:
1. **Check `/etc/hosts`**: Ensure that the hostname `salt` is correctly mapped to the appropriate IP address in your `/etc/hosts` file.
   ```bash
   cat /etc/hosts
   ```
You should see an entry like:
   ```bash
   127.0.0.1   salt
   ```
2. **Verify DNS Configuration**: Check your DNS settings in `/etc/resolv.conf` to ensure they are correct and that your system can resolve hostnames properly.

3. **Test Connectivity**: Use `ping` to check if you can reach the Salt master from within its own container:
   ```bash
   ./docker-compose.sh exec salt_master ping salt
   ```
4. **Run in Debug Mode**: If issues persist, run commands with debug logging for more detailed output:
   ```bash
   ./docker-compose.sh exec salt_master salt-call state.apply -l debug
   ```

### Summary
- For the first command, check minion connectivity and key acceptance.
- For the second command, verify DNS settings and ensure that the Salt master's hostname is correctly configured.

By following these interpretations and next steps, you should be able to diagnose and resolve issues related to your SaltStack setup effectively.