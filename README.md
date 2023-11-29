Personal Emacs configuration
============================

[GNU Emacs](https://www.gnu.org/software/emacs/) is the foundation for a text
editor customized to your wishes. This is my own setup. Feel free to take
inspiration from it and try out parts you like.

# Installing

Start by cloning this repository to your home directory. This would normally be
a command like `git clone https://github.com/czw/emacs.d.git ~/.emacs.d` from
your shell. You should also install these packages using your OS package manager:

* node (any version you prefer)
* ripgrep

## macOS specific

In order to detect when the system switches between light and dark mode, we
must be allowed to run a script. We have to ask for permission to do that.
Start a shell using `M-x eshell`, execute these commands and give Emacs
permission to the system:

```shell
osascript -e 'tell app "System Events" to display dialog "Hello"'
exit
```

Restart Emacs. It should now start without errors and match your system.

## Common

Install Tree-sitter grammars with `M-x czw/install-treesitter-grammars` and a
special symbols font with `M-x nerd-icons-install-fonts` inside Emacs.

You will probably want a few language servers installed as well.

* Typescript/TSX: `npm i -g typescript-language-server typescript`
