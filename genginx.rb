##
# Nginx config generator
# To keep the nginx conf DRY
#
# Written and copyrighted 2014+
# by Sven Marc 'cybrox' Gehring
# Licensed under CC-BY for sharing
#
# Dafack is dis thing?
#  Well, this is a simple ruby script for lazy admins.
#  I personally like to keep my configs small and readable
#  and this is perfect if you're using similar settings on all
#  your serverblocks anyways.
#
# Generator nginx configuration
#  {string } base:       Your web deirectory, the default nginx web directory is /usr/share/nginx/www
#  {string } ssld:       Your ssl file directory, I've set mine as a subfolder in /etc/nginx
#  {integer} http:       Your http port, default port is 80
#  {integer} https:      Your https port, default port is 443
#  { hash  } errors:     In this hash, you can define the target for every error redirect
#  { hash  } server:     In this hash will all your server blocks be defined (see below)
#  { hash  } additional: Additional config elements (see below)
#
# Server block configuration 
#  {string } root:       Document root. If you don't start this with an "/", the generator will add the ngix base in front
#  {boolean} http:       Defines if your server is accessable via http, if http and https are false, the generator will handle http as true
#  {boolean} https:      Defines if your server is accessable via https, you need to specify a 'sslcrt' parameter if you use this
#  {string } sslcrt:     Defines the name of your ssl .crt and .key file that should be stored in your nginx.ssld
#  {boolean} php:        Will include the PHP block if this is set to true
#  {boolean} rails:      If this is set to true, the default fallback to index.html/.php will not be included
#  {string } redirect:   Will just redirect the domain to the given address (drop the http:// in the target address!)
# 
# Additional configuration
#  Every element of this hash will just be placed on top of the server blocks
# 
# More config options
#  This generater is basically just a copy - pasting machine. It takes your parameters
#  and places them in the final config file. However, this of course allows you to
#  manipulate the generation in any way. Feel free to change the text blocks the generator
#  is using to change php / ssl settings.
#  ACTUALLY, you _should_ do this since this is just a sample config that might not contain
#  everything you need to run your server with all the functions you want it to have.
#
# Generate my config
#  To generate your config, simply set the $target variable to the right path and run the script.
#  The default setup here assumes that your genginx.rb file is located in /etc/nginx so it will
#  generate the config in /etc/nginx/sites-enabled/generated. You may change this however you need to.
#  To finally get the magic done, run "ruby genginx.rb" and "service nginx reload" the config.
#
## important notes (currently known bugs)
# - additionals are wrong formatted
# - redirects are not working yet
#
# /enjoy your cookies
$target = 'sites-enabled/generated'	# Output path and filenam for the generated config file

nginx = {
	base: "/usr/share/nginx/www/",
	ssld: "/etc/nginx/ssl/",
	http: "80",
	https: "443",
	errors: {
		"403" => "misc/error/403.html",
		"404" => "misc/error/404.html",
		"500" => "misc/error/500.html"
	},
	server: {
		"localhost" => { root: "" },

		# Insert your server blocks here.
		# 
		# Example Redirect:
		#  "red.irect.me" => { redirect: "google.com"  },
		#
		# Simple example block:
		#  "s.cybrox.eu" => { root: "myfolder", php: true },
		# 
		# Complex example block:
		#  "www.domain.tld domain.tld" => {
		#     root: "domainfolder",
		#     http: true,
		#     https: true,
		#     sslcrt: "domaincertificate",
		#     php: true
		#  },
		#
		# Example block for a rails / unicorn seup
		#  "unicorn.domain.tld" => {
		#     root: "/var/www/rails-project/public",
		#     http: true,
		#     https: true,
		#     sslcrt: "domaincertificate",
		#     php: false,
		#     rails: true,
		#     rules: {
		#        "/" => "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\nproxy_set_header Host $http_host;\nproxy_redirect off;\nif (!-f $request_filename) {\nproxy_pass http://unicorn_cs;\nbreak;\n}"
		#     }
		#  }

	},
	additional: {

		# Inset your additional rules here
		#
		# Example for a unicorn upstream
		#  "Unicorn Server" => "upstream unicorn_cs {\n\tserver unix:/var/www/rails-project/tmp/pids/unicorn.sock fail_timeout=0;\n}"
	}
}










#================================================================================================
#== Beware, shiny magic and cute cookies inside, do not crunch!
#================================================================================================
$filestring = Array.new
def fput(line)
	$filestring.push(line)
end


# Write additional Pre-content
nginx[:additional].each do |name, rule|
	fput rule
end
nginx[:server].each do |name, srv|
	# Give the user some feedback
	puts "<genginx> Writing server details for #{name}"

	# Write basic informations and server block
	fput "\n\n\nserver {"
	fput "\tlisten #{nginx[:http]};" if(srv[:http] || (srv[:http].nil? && srv[:https].nil?))
	fput "\tlisten #{nginx[:https]};" if srv[:https]
	fput "\tserver_name #{name};"

	# Add redirect and skip if site is a redirect
	if !srv[:redirect].nil?
		fput "\treturn 301 $scheme://#{srv[:redirect]}$request_uri;\n}"
		next
	end

	# Write root and index definitions
	frot = (srv[:root].chars.first == "/") ? srv[:root] : "#{nginx[:base]}#{srv[:root]}"
	fput "\troot #{frot};"
	fput "\tindex index.html index.php;"

	# Add routes for erros
	nginx[:errors].each do |error, target|
		fput "\terror_page #{error} #{nginx[:base]}#{target};";
	end

	# Provide default fallback for files
	if !srv[:rails]
		fput "\tlocation / {"
		fend = srv[:php] ? "php" : "html"
		fput "\t\ttry_files $uri $uri/ /index.#{fend};"
		fput "\t}"
	end

	# Write PHP block if PHP is enabled
	if srv[:php]
		fput "\tlocation ~ \.php$ {"
		fput "\t\tfastcgi_split_path_info ^(.+\.php)(/.+)$;"
		fput "\t\tfastcgi_pass 127.0.0.1:9000;"
		fput "\t\tfastcgi_index index.php;"
        fput "\t\tfastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;"
		fput "\t\tinclude fastcgi_params;"
		fput "\t}"
	end

	# Write HTTPS block if HTTPS is enabled
	if srv[:https]
		fput "\tssl on;"
		fput "\tssl_certificate #{nginx[:ssld]}#{srv[:sslcrt]}.crt;"
		fput "\tssl_certificate_key #{nginx[:ssld]}#{srv[:sslcrt]}.key;"
		fput "\tssl_session_timeout 5m;"
		fput "\tssl_protocols SSLv3 TLSv1;"
		fput "\tssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;"
		fput "\tssl_prefer_server_ciphers on;"
	end

	# Write additional path rules
	if srv[:rules]
		srv[:rules].each do |path, rule|
			rule.gsub! '\n', '\n\t\t' #not working
			fput "\tlocation #{path} {"
			fput "\t\t#{rule}"
			fput "\t}"
		end
	end

	fput "}"
end


# Write generated confîg to the file
File.open($target, 'w') do |cfg|
	cfg.puts $filestring.join("\n")
end

# Notify user that everything is done
puts "<genginx> Successfully generated config for #{nginx[:server].count} serverblocks."