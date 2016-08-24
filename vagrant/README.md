Notes
-----

To disable the default Vagrant synced folder (`/vagrant`), you need to add the
following snippet to your `Vagrantfile`:

~~~ruby
config.vm.synced_folder ".", "/vagrant", disabled: true
~~~

*This might be also needed on Windows, since rsync is not installed by default*.
