# Vagrant AWS Example Box

copped from https://github.com/mitchellh/vagrant-aws/tree/master/example_box

Vagrant providers each require a custom provider-specific box format.
This folder shows the example contents of a box for the `aws` provider.
To turn this into a box:

```
$ tar cvzf aws_{{ project_name }}.box ./metadata.json ./Vagrantfile
```

This box works by using Vagrant's built-in Vagrantfile merging to setup
defaults for AWS. These defaults can easily be overwritten by higher-level
Vagrantfiles (such as project root Vagrantfiles).
