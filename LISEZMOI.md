# InstallMSE

Installateur *MSEide+MSEgui* pour la ligne de commande.

## Ce qu'il fait

- Cloner le dépôt *git* de *MSEide+MSEgui*
- Compiler *MSEide*
- Configurer *MSEide*
- Créer un script de lancement et des raccourcis

Le script de lancement et les raccourcis sont créés avec l'option **--globstatfile** (en sorte que chaque binaire de *MSEide* installé utilise son propre fichier de configuration).

## Usage

```Bash
./installmse [--dir=DIR]
```

Où **DIR** est l'emplacement du dossier *mseide-xxxxxxxxxx*.

Exemple :

```Bash
./installmse --dir=/home/roland/Applications 2> installmse.debug
```

Par défaut le dossier est créé dans le répertoire courant.

## Compilation

```Bash
make
```

Par défaut l'installateur est compilé en mode passif. (Il créera les scripts mais ne lancera aucune commande.)

Pour compiler en mode actif :

```Bash
make RELEASE=1
```

## Essai

Pour essayer le programme :

```Bash
make distclean && make test
```

```
'mseide-2603221716.desktop' supprimé
'desktopfile.o' supprimé
'installmse.o' supprimé
'readversion.o' supprimé
'desktopfile.ppu' supprimé
'readversion.ppu' supprimé
'build-mseide-2603221716.sh' supprimé
'start-mseide-2603221716.sh' supprimé
'installmse' supprimé
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
MSEinstall 0.2 (FPC 3.2.2 2026/03/22 17:17:02 Linux-x86_64)
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
