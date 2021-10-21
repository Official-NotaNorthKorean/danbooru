#!/bin/bash

# Run: curl -L -s https://raw.githubusercontent.com/danbooru/danbooru/master/INSTALL.debian -o install.sh ; chmod +x install.sh ; ./install.sh

export RUBY_VERSION=3.0.2
export GITHUB_INSTALL_SCRIPTS=https://raw.githubusercontent.com/danbooru/danbooru/master/script/install
export VIPS_VERSION=8.7.0

if [[ "$(whoami)" != "root" ]] ; then
  echo "You must run this script as root"
  exit 1
fi

verlte() {
  [ "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
  [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

echo "* DANBOORU INSTALLATION SCRIPT"
echo "*"
echo "* This script will install all the necessary packages to run Danbooru on a   "
echo "* FreeBSD server."
echo
echo -n "* Enter the hostname for this server (ex: danbooru.donmai.us): "
read HOSTNAME

if [[ -z "$HOSTNAME" ]] ; then
  echo "* Must enter a hostname"
  exit 1
fi

# Install packages
#echo "* Installing packages..."

#pkg update
#pkg upgrade
#pkg install glib automake libxml2 libxslt ncurses sudo readline flex bison ragel redis git curl sendmail nginx ssh ffmpeg mkvtoolnix postgresql96-client postgresql96-server lcms2 expat libgif libspng libexif gcc perl5 node yarn vips
#pkg install exiftool 
pkg remove py38-cmdtest
#
#if [ $? -ne 0 ]; then
#  echo "* Error installing packages; aborting"
#  exit 1
#fi

# Create user account
pw useradd danbooru -s bash -g danbooru wheel

# Set up Postgres
export PG_VERSION=`pg_config --version | egrep -o '[0-9]{1,}\.[0-9]{1,}[^-]'`

# Install rbenv
echo "* Installing rbenv..."
cd /tmp
sudo -u danbooru git clone git://github.com/sstephenson/rbenv.git ~danbooru/.rbenv
sudo -u danbooru touch ~danbooru/.bash_profile
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~danbooru/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~danbooru/.bash_profile
sudo -u danbooru mkdir -p ~danbooru/.rbenv/plugins
sudo -u danbooru git clone git://github.com/sstephenson/ruby-build.git ~danbooru/.rbenv/plugins/ruby-build
sudo -u danbooru bash -l -c "RUBY_CONFIGURE_OPTS=--disable-install-doc rbenv install --verbose $RUBY_VERSION"
sudo -u danbooru bash -l -c "rbenv global $RUBY_VERSION"

# Install gems
echo "* Installing gems..."
sudo -u danbooru bash -l -c 'gem install --no-ri --no-rdoc bundler'

echo "* Install configuration scripts..."

# Update PostgreSQL
curl -L -s $GITHUB_INSTALL_SCRIPTS/postgresql_hba_conf -o /usr/local/etc/postgresql/$PG_VERSION/main/pg_hba.conf
sudo service postgresql restart
sudo -u postgres createuser -s danbooru
sudo -u danbooru createdb danbooru2

# Setup nginx
curl -L -s $GITHUB_INSTALL_SCRIPTS/nginx.danbooru.conf -o /etc/nginx/sites-enabled/danbooru.conf
sed -i -e "s/__hostname__/$HOSTNAME/g" /etc/nginx/sites-enabled/danbooru.conf
sudo service nginx restart

# Setup danbooru account
echo "* Enter a new password for the danbooru account"
passwd danbooru

echo "* Setting up SSH keys for the danbooru account"
sudo -u danbooru ssh-keygen -t rsa -f ~danbooru/.ssh/id_rsa -N ""
sudo -u danbooru touch ~danbooru/.ssh/authorized_keys
sudo -u danbooru cat ~danbooru/.ssh/id_rsa.pub >> ~danbooru/.ssh/authorized_keys
sudo -u danbooru chmod 600 ~danbooru/.ssh/authorized_keys

mkdir -p /usr/local/www/danbooru2/shared/config
mkdir -p /usr/local/www/danbooru2/shared/data
mkdir -p /usr/local/www/danbooru2/shared/data/preview
mkdir -p /usr/local/www/danbooru2/shared/data/sample
chown -R danbooru:danbooru /usr/local/www/danbooru2
curl -L -s $GITHUB_INSTALL_SCRIPTS/danbooru_local_config.rb.templ -o /usr/local/www/danbooru2/shared/config/danbooru_local_config.rb

echo "* Almost done! You are now ready to deploy Danbooru onto this server."
echo "* Log into Github and fork https://github.com/danbooru/danbooru into"
echo "* your own repository. Clone your fork onto your local development"
echo "* machine and modify the following files:"
echo "*"
echo "*   config/deploy.rb (github repo url)"
echo "*   config/deploy/production.rb (servers and users)"
echo "*   config/unicorn/production.rb (users)"
echo "*   config/application.rb (time zone)"
echo "*"
echo "* On the remote server you will want to modify this file:"
echo "*"
echo "*   /usr/local/www/danbooru2/shared/config/danbooru_local_config.rb"
echo "*"
read -p "Press [enter] to continue..."
echo "* Commit your changes and push them to your fork. You are now ready to"
echo "* deploy with the following command:"
echo "*"
echo "*   bundle exec cap production deploy"
echo "*"
echo "* You can also run a server locally without having to deal with deploys"
echo "* by running the following command:"
echo "*"
echo "*   bundle install"
echo "*   bundle exec rake db:create db:migrate"
echo "*   bundle exec rails server"
echo "*"
echo "* This will start a web process running on port 3000 that you can"
echo "* connect to. This is useful for development and testing purposes."
echo "* If something breaks post about it on the Danbooru Github. Good luck!"
