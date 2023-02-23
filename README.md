# CASS - Chris Arch-Linux Setup Script

## Scope

This shellscript sets up system configuration for different devices.
Those systems can be `mobile` or `desktop`. According to those **choices**,
software is installed. The scope of this script is to speed up the configuration process.


For `.dotfiles` setup have a look at my other [repo](htts://github.com/ckiri/dotfiles).



The script creates a User as well as a home directory. It installs the software
found in this [file](https://github.com/ckiri/cass/blob/master/sw.csv).

## Setup/Installation

### Prerequisites

* A fresh install of Arch-Linux or a Arch based distribution.
* Git has to be installed

### How To

Clone this **repository** and **run** the script:

```sh
git clone https://github.com/ckiri/cass
cd cass
./cass.sh
```

