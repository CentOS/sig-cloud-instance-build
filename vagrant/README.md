Notes:

In order to disable the rsync option in your Vagrantfile, you need to use this snippet:

~~~ruby
config.vm.synced_folder ".", "/home/vagrant/sync", disabled: true
~~~

