# Minimal syndics configuration

## Minimal /etc/salt/master configuration
here are the minimal parameters that should be found in the /etc/salt/master file of a syndic:
- syndic_master: The IP address or hostname of the higher-level master to which the syndic should connect.
```text
syndic_master: <ip_address_or_hostname_of_higher_level_master>
```
- syndic_master_port: The port of the higher-level master (optional, default is 4506).
```text
syndic_master_port: 4506
```
- order_masters: While this parameter is typically configured on the higher-level master, it can be useful to set it on the syndic as well to ensure that the necessary additional information is sent.
```text
order_masters: True
```
- id: A unique identifier for the syndic (shared with the potential salt-minion daemon on the same system).
```text
id: <unique_syndic_identifier>
```
- file_roots: Each syndic must provide its own file_roots directory.
```text
file_roots:
  base:
    - /srv/salt
```
These parameters are essential for the syndic to function correctly as an intermediary between the higher-level master and the minions connected to it. Remember that the syndic also requires a minion configuration (typically in /etc/salt/minion) to connect to the higher-level master.


## Minimal /etc/salt/minion configuration
Minimal parameters that should be found in the /etc/salt/minion file of a syndic:

1. master: The IP address or hostname of the master to which the syndic should connect as a minion.
```text
master: <ip_address_or_hostname_of_master>
```

2. id: A unique identifier for the syndic.
```text
id: <unique_syndic_identifier>
```
3. file_client: This parameter should be set to "remote" so that the syndic can retrieve files from the master.
```text
file_client: remote
```
4. pki_dir: The directory where the syndic's public and private keys are stored.
```text
pki_dir: /etc/salt/pki/minion
```

These parameters are essential for the syndic to function correctly as a minion in relation to the main master.
It's important to note that this configuration is separate from the syndic's configuration as a master (which is found in /etc/salt/master). The minion configuration allows the syndic to communicate with the main master, while the master configuration allows it to manage its own minions.


For the "master:" parameter in the /etc/salt/minion file of a syndic, you should specify the address of the higher-level master, not the hostname of the syndic itself.
Here's why:
1. The /etc/salt/minion file on a syndic configures the syndic's behavior as a minion in relation to the higher-level master.
2. The "master:" parameter in this file tells the syndic where to find its master, which is the higher-level master it needs to connect to.
3. This configuration allows the syndic to communicate with the higher-level master as if it were a normal minion.
Therefore, the correct configuration would be:
```text
master: <ip_address_or_hostname_of_higher_level_master>
```
Where <ip_address_or_hostname_of_higher_level_master> is the IP address or hostname of the higher-level master to which the syndic should connect.
This configuration enables the syndic to play its role as an intermediary between the higher-level master and the minions connected to it.