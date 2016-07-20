#Notes

##Disable rsync folder

In order to disable the rsync option in your Vagrantfile, you need to use this snippet:

~~~ruby
config.vm.synced_folder ".", "/home/vagrant/sync", disabled: true
~~~

##Setup VirtualBox shared folder at /vagrant

Install vagrant-vbguest

~~~bash
$ vagrant plugin install vagrant-vbguest
~~~

Add this to Vagrantfile

~~~ruby
config.vm.synced_folder ".", "/vagrant"
~~~
