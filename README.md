# SaltStack Architecture with Docker Compose

This repository contains a `docker-compose.yml` file that sets up a SaltStack architecture using Docker. The configuration defines multiple services, including a Salt master, syndics, minions, and additional components like the Salt API and SaltPad. This setup allows for easy management and orchestration of systems using SaltStack's powerful configuration management capabilities.

## Overview of the Architecture

The architecture consists of the following key components:

- **Salt Master**: 
  - The central server that manages the state and configuration of all minions. It communicates with syndics and minions to ensure they are in the desired state as defined in configuration files.

- **Syndics**: 
  - These act as intermediaries between the master and minions. They help distribute commands from the master to local minions, allowing for more scalable management across larger infrastructures.

- **Salt Minion**: 
  - The agent installed on each managed system. Minions receive commands from the master or syndics and report back their status or results.

- **Salt API**: 
  - Provides a RESTful interface for interacting with SaltStack, allowing for integration with other applications or services.

- **SaltPad**: 
  - A web-based interface for managing SaltStack configurations through the Salt API, making it easier to visualize and control your infrastructure.

## Benefits of Using Docker Compose

1. **Isolation**: Each component runs in its own container, ensuring that dependencies and configurations do not interfere with one another.

2. **Scalability**: Easily scale up or down the number of minions or syndics by modifying the `docker-compose.yml` file. For example, you can increase the number of minion instances to test how your architecture handles multiple agents.

3. **Simplified Management**: Docker Compose simplifies the process of starting, stopping, and managing multiple containers as a single application. You can bring up your entire SaltStack environment with a single command.

4. **Development and Testing**: This setup provides a convenient environment for developing and testing SaltStack configurations without needing to set up physical or virtual machines.

5. **Networking**: All services are connected through a custom network (`salt-network`), facilitating seamless communication between components.

## Getting Started

To start the SaltStack architecture defined in this `docker-compose.yml`, follow these steps:

1. Ensure you have Docker and Docker Compose installed on your machine.
2. Clone this repository:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```
3. Build and start all services:
   ```bash
    ./docker-compose-init.sh
   ```

4. Access the Salt API at http://localhost:8000 and SaltPad at http://localhost:8080.

## Utilities
- ./check-heath.sh      : check health of the SaltStack architecture
- ./login-master.sh     : login into the Salt master container
- ./login-syndic.sh     : login into the Salt syndic container
- ./login-minion.sh     : login into the Salt minion container
- ./docker-compose.sh   : run any docker-compose command
- ./config-exports.sh   : export all salt configuration files from the containers (master, syndics, minions) into _exports
- _templates            : contains master/minion templates
- _logs                 : contains logs of all utils scripts
- _exports              : contains exports of configuration files for master, syndics, minions

## Conclusion
This Docker Compose configuration provides a robust foundation for working with SaltStack in a containerized environment. It is ideal for learning, testing, and developing configuration management practices using SaltStack.