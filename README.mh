## Dafack is dis thing?
Well, this is a simple ruby script for lazy admins.
I personally like to keep my configs small and readable
and this is perfect if you're using similar settings on all
your serverblocks anyways.

## Generator nginx configuration
`{string} base:` Your web deirectory, the default nginx web directory is /usr/share/nginx/www
`{string} ssld:` Your ssl file directory, I've set mine as a subfolder in /etc/nginx
`{integer} http:` Your http port, default port is 80
`{integer} https:` Your https port, default port is 443
`{hash} errors:` In this hash, you can define the target for every error redirect
`{hash} server:` In this hash will all your server blocks be defined (see below)
`{hash} additional:` Additional config elements (see below)

## Server block configuration 
`{string } root:` Document root. If you don't start this with an "/", the generator will add the ngix base in front
`{integer} http:` Defines if your server is accessable via http, if http and https are false, the generator will handle http as true
`{integer} https:` Defines if your server is accessable via https, you need to specify a 'sslcrt' parameter if you use this
`{string } sslcrt:` Defines the name of your ssl .crt and .key file that should be stored in your nginx.ssld
`{boolean} php:` Will include the PHP block if this is set to true
`{boolean} rails:` If this is set to true, the default fallback to index.html/.php will not be included
`{string } redirect:` Will just redirect the domain to the given address (drop the http:// in the target address!)

## Additional configuration
Every element of this hash will just be placed on top of the server blocks

## More config options
This generater is basically just a copy - pasting machine. It takes your parameters
and places them in the final config file. However, this of course allows you to
manipulate the generation in any way. Feel free to change the text blocks the generator
is using to change php / ssl settings.
ACTUALLY, you _should_ do this since this is just a sample config that might not contain
everything you need to run your server with all the functions you want it to have.

## Generate my config
To generate your config, simply set the $target variable to the right path and run the script.
The default setup here assumes that your genginx.rb file is located in /etc/nginx so it will
generate the config in /etc/nginx/sites-enabled/generated. You may change this however you need to.
To finally get the magic done, run "ruby genginx.rb" and "service nginx reload" the config.

## important notes (currently known bugs)
- additionals are wrong formatted
- redirects are not working yet

/enjoy your cookies