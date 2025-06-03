#!/bin/bash


if [[ "$OSTYPE" == "linux-gnu" ]]; then
	# ubuntu installs
	echo "Detected Linux. Starting setup..."

	echo "Updating package list..."
	sudo apt update

	echo "Installing essential packages..."
	sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
	libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
	xz-utils tk-dev libffi-dev liblzma-dev python-openssl git ncdu htop unzip  

	# uv
	echo "Installing uv..."
	curl -LsSf https://astral.sh/uv/install.sh | sh

	# zsh
	echo "Installing Zsh..."
	sudo apt-get install -y zsh 
	sudo chsh -s /bin/zsh $(whoami)

	echo "Installing Oh My Zsh..." 
	sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

elif [[ "$OSTYPE" == "darwin"* ]]; then
	#macos
	echo "Detected macOS. Starting setup..."
	
	#uv
	echo "Installing uv..."
	brew install uv
	
	# zsh
	echo "Installing Zsh..."
	brew install zsh
	chsh -s $(which zsh)

	echo "Installing Oh My Zsh..." 
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	
else
	echo "unknown OSTYPE: $OSTYPE" 
fi

#################################################

# autosuggestion
export ZSH_CUSTOM=~/.oh-my-zsh/custom
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# power10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

#################################################

cd ~
sudo rm -r .zshrc
sudo ln -s .files/zsh/.zshrc .zshrc
sudo ln -s .files/screen/.screenrc .screenrc
sudo ln -s .files/nano/.nanorc .nanorc

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

source ~/.zshrc
