# Kook

Kook is a helper for opening your projects environments in tabs of KDE Konsole.


## Installation

Simply install kook via the 'gem' package manager 

    $ gem install kook


## Usage

Imagine, that for working on your project, you requires multiple terminal consoles,
with different tools in them. 

Let say that :

    A : must be in directory ~/src/myProject/
    B : must be in directory ~/src/myProject/app
        and run command "$EDITOR ."
    C : must be in directory ~/src/myProject/log
        and run command "tail -f development.log"

Kook aims to prepare your project environment, just like you want it to be,
with all you tabs and the commands inside in the right directories. Everything
in one single command.


## Contributing

1. Fork it ( http://github.com/glenux/kook/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## Alternatives

  * Tmuxinator (the same goal, based on tmux instead of Konsole)

