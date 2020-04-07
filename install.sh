#!/bin/bash
alias gcd1="git clone --depth=1"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
	# zsh
    	sudo apt-get update 
	sudo apt-get install -y zsh 
	sudo chsh -s /bin/zsh $(whoami) 
	sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

	# solarized
	sudo apt-get install dconf-cli
	gcd1 https://github.com/aruhier/gnome-terminal-colors-solarized.git
	cd gnome-terminal-colors-solarized
	./install.sh

elif [[ "$OSTYPE" == "darwin"* ]]; then
        # zsh
	brew install zsh
	chsh -s $(which zsh)
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	
	# solarized
	cd ~/Documents;\
	gcd1 https://github.com/altercation/solarized
	echo "go to Terminal > Preferences and import the color scheme"

else
	echo "unknown OSTYPE: $OSTYPE" 
fi

cd ~

# pyenv
sudo apt install python3-venv
export PYENV_ROOT="~/.pyenv"
sudo gcd1 https://github.com/pyenv/pyenv.git $PYENV_ROOT
sudo gcd1 https://github.com/pyenv/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv


# autosuggestion
export ZSH_CUSTOM=~/.oh-my-zsh/custom
sudo gcd1 https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTUM/plugins/zsh-autosuggestions
sudo gdc1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTUM/plugins/zsh-syntax-highligh$

#################################################
sudo rm -r .zshrc
sudo ln -s .dotfiles/zsh/.zshrc .zshrc

# power10k
sudo gcd1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

exec "$SHELL"
