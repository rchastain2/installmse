# InstallMSE

*MSEide+MSEgui* installer for command-line.

## What it does

- Clone *MSEide+MSEgui* *git* repository
- Build *MSEide*
- Configure *MSEide*
- Create start script and desktop shortcuts

The start script and the desktop shortcuts are created with **--globstatfile** option (so that each *MSEide* binary installed by this program use its own configuration file).

## Usage

```Bash
./installmse [--dir=DIR]
```

Where **DIR** is the location of the folder *mseide-xxxxxxxxxx*.

Example:

```Bash
./installmse --dir=/home/roland/Applications
```

If the location is not specified, the folder is created in the current directory.

## Compilation

```Bash
make
```

By default the program is compiled in passive mode. (It will create the scripts but won't execute any command.)

To build in active mode:

```Bash
make RELEASE=1
```

## Test

To test the program:

```Bash
LC_ALL=C make distclean && make test
```

```
removed 'mseide-2603221717.desktop'
removed 'desktopfile.o'
removed 'installmse.o'
removed 'readversion.o'
removed 'desktopfile.ppu'
removed 'readversion.ppu'
removed 'build-mseide-2603221717.sh'
removed 'start-mseide-2603221717.sh'
removed 'installmse'
Free Pascal Compiler version 3.2.2 [2023/03/05] for x86_64
Copyright (c) 1993-2021 by Florian Klaempfl and others
Target OS: Linux for x86-64
Compiling installmse.pas
Compiling desktopfile.pas
Compiling readversion.pas
installmse.pas(111,5) Warning: unreachable code
installmse.pas(128,5) Warning: unreachable code
installmse.pas(148,5) Warning: unreachable code
installmse.pas(186,9) Warning: unreachable code
installmse.pas(200,7) Warning: unreachable code
Linking installmse
320 lines compiled, 0.8 sec
5 warning(s) issued
./installmse --dir=/home/roland/Applications 2> installmse.debug
MSEinstall 0.2 (FPC 3.2.2 2026/03/22 17:18:15 Linux-x86_64)
[INFO] Mode SIMULATION
[INFO] Check command-line
[INFO] Set variables
[INFO] Clone repository
[INFO] Create script to build MSEide
[INFO] Build MSEide
[INFO] Create script to start MSEide
[INFO] Configure MSEide
[WARNING] Cannot find directory "/home/roland/Bureau"
[INFO] Done
```
