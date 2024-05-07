# EOS Demo Project

## Overview

A small coop vampire survivor clone. Mostly a way to experiment with epic online services in the godot engine.

Epic online services are a collection of utilities epic provides for free to facilitate making online games. The services are broken into a series of 'interfaces'.

This project uses the peer to peer interface to allow players to join games with each other without having to do port forwarding or use dedicated servers.

EOS requires you set up a project through their web portal before you can use any interfaces. This project already has credentials for a project hard coded into the `eos_client.gd` file. You can set up your own following these directions - https://github.com/LowFire/EOSGP2PInterfaceTestGame.

## Running the game

1. Install Godot 4.2
2. Clone this repo
3. Run eos_tools/EOS_DevAuthTool/EOS_DevAuthTool.exe. This must be running to log in with a dev account
4. Log into the dev auth tool and create a user
5. Launch the project in godot
6. Debug -> Run Multiple Instances -> 2
7. Launch the game
8. In one game check 'use dev account' and 'start new game'. In the other, join game
9. Copy the game id from the host to the guest and start the game


## External Assets

* Epic Online Services Godot library - https://github.com/3ddelano/epic-online-services-godot
* Used Kenney's Assets coin.glb
