# InstallMSE

*MSEide* command-line installer designed for multiple installations.

The installation involves:

1. cloning *MSEide+MSEgui* *git* repository
2. building *MSEide*
3. configuring *MSEide*
4. creating start script
5. creating desktop shortcuts (Linux)

## Usage

```Bash
./installmse [--dir=DIR]
```

Where **DIR** is the location of the folder *mseide-xxxxxxxxxx*.

Example:

```Bash
./installmse --dir=/home/roland/Applications
```

If the location is not specified, the folder *mseide-xxxxxxxxxx* is created in the current directory.

## Compilation

```Bash
git clone https://github.com/rchastain2/installmse.git
cd installmse
git clone https://github.com/mse-org/mseide-msegui.git
make
```

By default the program is compiled in passive mode: It creates build and start scripts but doesn't launch commands.

Build in active mode:

```Bash
make RELEASE=1
```
