# Paho_MQTT
This repo frames the Eclipse Paho MQTT C/C++ client as a CMSIS-Pack  (upstream: https://github.com/eclipse/paho.mqtt.embedded-c)

## Prerequisites
Working with this repository requires the following applications and packs to be installed on your PC:
- bash compatible shell (under Windows, use for example [git bash](https://gitforwindows.org/))
- ZIP archive creation utility (e.g. [7-Zip](https://www.7-zip.org/))
- CMSIS Pack installed in CMSIS_PACK_ROOT (for PackChk utility)
- [Doxygen version 1.8.6](https://sourceforge.net/projects/doxygen/files/rel-1.8.6/)

## Instructions
1. Open a bash compatible shell
2. Clone the repository: `git clone https://github.com/MDK-Packs/Paho_MQTT.git`
3. Run `./gen_pack.sh`. It fetches a preconfigured version of the upstream repository, adds a set of files contained in the directory named `./contributions`, and creates a CMSIS-Pack file.
4. Install the pack created in the root directory (e.g. double-click on the pack file)

## Directory structure
The directory structure is as follows:  
- `./contributions/add`: contains files for inclusion into the pack that are not (yet) present in the upstream repository  
- `./contributions/merge`: contains files that are present in the public upstream GitHub repository but have been modified to
   become fit for use in MDK and Arm DS.

*Note:* The aim is to make the files from the 'add' and 'merged' folders part of the upstream repository via pull-requests. Once all files are included in the upstream repository this repository will become obsolete.
