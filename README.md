# x10's MoErgo Glove80 Custom Configuration for ZMK

![MoErgo Logo](moergo_logo.png)

This repo is a fork of the official ZMK configuration of the MoErgo Glove80 wireless split contoured keyboard.
Feel free to fork it to develop your own keymap _and_ easily build your own ZMK firmware to run on your Glove80.

This repo automates the build with GitHub Workflow Actions, so each `git push` will automatically test-build your version of `glove80.uf2`.
If you push a `git tag`, it will also make a "release", which you can easily find on the right-hand side of the repo's "home page" in a desktop browser.

**NOTE: You can also customize the layout of your Glove80 keyboard with the Glove80 Layout Editor webapp. For most users Glove80 Layout Editor is the recommended and simpler option. More information is available at the official MoErgo Glove80 Support site (see resources below).**

## Local development
Ensure you have the following installed:
1. [`nix`](https://nixos.org/download) package manager system
1. Ensure nix `flakes` and `nix-command` features are enabled for your user (if not already):
   - `echo "experimental-features = nix-command flakes" | tee -a ~/.config/nix/nix.conf`
1. Install [direnv](https://github.com/direnv/direnv)

Thereafter, do this whenever you want to work on this locally:
1. `cd <into this locally cloned repo>`
   - For ease-of-use, if you can execute the one-time command `direnv allow`, if you use and trust direnv/this fork.
     **Only necessary to execute this command _once_.**
1. Each time you want to build locally; `nom build`
   - If successful, your firmware file can be found in `result/glove80.uf2`

### Generate SVG of layout
Only do once:
1. Ensure local development tools are installed
1. Run `pipx install keymap-drawer` (one-time operation)

Every time you want to generate the svg (after the above has been done):
1. `keymap parse --zmk-keymap config/glove80.keymap | keymap draw - > keymap.svg`

## Resources
- The [moergo-sc/glove80-zmk-config](https://github.com/moergo-sc/glove80-zmk-config) repository this is forked from.
- Further documentation/resource links available there at the time of this writing.
 
## Instructions
1. Log into, or sign up for, your personal GitHub account.
2. Create your own repository using this repository as a template ([instructions](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)) and check it out on your local computer.
3. Edit the keymap file(s) to suit your needs, and commit your changes with git.
   1. Optionally, push your changes to your personal repo.
      Upon pushing it, GitHub Actions will start building a new version of your firmware with the updated keymap.
5. Push a `git tag`, and GitHub Actions will make the firmware file easily downloadable as a release, built from the commit the tag points to.

## Firmware Files
To locate your firmware files and reflash your Glove80...
1. Open your fork of this repo in a browser.
1. Find the release version you want to download the firmware of.
1. Download the glove80.uf2.
1. Flash the firmware to Glove80 according to the user documentation on the official Glove80 Glove80 Support website (linked above).

Your keyboard is now ready to use.
