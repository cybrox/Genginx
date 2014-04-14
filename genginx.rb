##
# Nginx config generator
# To keep the genginx conf DRY
#
# Written and copyrighted 2014+
# by Sven Marc 'cybrox' Gehring 
# Licensed under CC-BY for sharing
#
# (Temporarly removed the rest of the docs since they're invalid now)
#
# /enjoy your cookies
genginx = {
	path: {
		ssld: '/etc/nginx/ssl/',
		conf: '/etc/nginx/sites-enabled/generated',
		base: '/usr/share/nginx/www/'
	},
	port: {
		http: "80",
		https: "443"
	},
	errors: {
		"403" => "misc.error/403.html",
		"404" => "misc.error/404.html",
		"500" => "misc.error/500.html"
	},
	server: {
		# Servers
	},
	additional: {
		# Additional stuff
	}
}










#================================================================================================
#== Beware, shiny magic and cute cookies inside, do not crunch!
#================================================================================================
$confstring = "";
$conflevels = 0;



# @function dput
# @name Do Put
# @desc Split a text block into single lines,
#       strip them and send them to fput
# @param {string} lines - The line(s) to add
def dput(lines)
	lines.split('\n').each do |line|
		line.strip! unless line.strip.nil?
		fput line
	end
end

# @function fput
# @name File Put
# @desc Add a line to the generated config string
#       and append automatic formatting characters
# @param {sting} line - The line to add
def fput(line)
	line.strip! unless line.strip.nil?
	$conflevels -= 1 if line.include? "}"

	format = "\n";
	format += "\n\n" if($conflevels == 0 && line.include?("{"))
	(1..$conflevels).each do |i|
		format += "\t"
	end
	
	$conflevels += 1 if line.include? "{"
	$confstring << "#{format}#{line}"
end

# @function cput
# @name Console Put
# @desc Output a genginx log message to the console
# @param {string} message - The respective message
def cput(message)
	puts "<genginx> (=^.^=) "+message
end



# Write additional pre-content
genginx[:additional].each do |name, rule|
	cput "Writing additional block #{name}"
	lines = rule.split("\n")
	lines.each do |line|
		line.strip! unless line.strip.nil?
		fput line
	end
end

# Loop through server blocks
genginx[:server].each do |name, srv|
	cput "Recognized server block #{name}"
	cput "Writing definitions for #{name}"

	# Write basic informations and server block
	fput "server {"
	fput "listen #{genginx[:port][:http]};" unless !srv[:http]
	fput "listen #{genginx[:port][:https]};" if srv[:https]
	fput "server_name #{name};"

	# Add redirect and skip if site is a redirect
	if !srv[:redirect].nil?
		fput "\treturn 301 $scheme://#{srv[:redirect]}$request_uri;\n}"
		next
	end

	# Write root and index definitions
	frot = (srv[:root].chars.first == "/") ? srv[:root] : "#{genginx[:path][:base]}#{srv[:root]}"
	fput "root #{frot};"
	fput "index index.html index.php;"

	# Add routes for erros
	genginx[:errors].each do |error, target|
		errdoc = target.split('/').last
		errpth = target[0..(errdoc.length+1)]
		fput "error_page #{error} /#{errdoc};";
		fput "location /#{errdoc} {"
		fput "root #{genginx[:path][:base]}#{errpth};"
		fput "}"
	end

	# Provide default fallback for files
	if(!srv[:rails] && !srv[:notry])
		fput "location / {"
		fend = srv[:php] ? "php" : "html"
		fput "try_files $uri $uri/ /index.#{fend};"
		fput "}"
	end

	# Write PHP block if PHP is enabled
	if srv[:php]
		fput "location ~ \.php$ {"
		fput "fastcgi_split_path_info ^(.+\.php)(/.+)$;"
		fput "fastcgi_pass 127.0.0.1:9000;"
		fput "fastcgi_index index.php;"
        fput "fastcgi_param  SCRIPT_FILENAME  $document_root$request_filename;"
		fput "include fastcgi_params;"
		fput "}"
	end

	# Write HTTPS block if HTTPS is enabled
	if srv[:https]
		fput "ssl on;"
		fput "ssl_certificate #{genginx[:path][:ssld]}#{srv[:sslcrt]}.crt;"
		fput "ssl_certificate_key #{genginx[:path][:ssld]}#{srv[:sslcrt]}.key;"
		fput "ssl_session_timeout 5m;"
		fput "ssl_protocols SSLv3 TLSv1;"
		fput "ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;"
		fput "ssl_prefer_server_ciphers on;"
	end

	# Write additional path rules
	cput "Fetching additional rules for #{name}"
	if srv[:rules]
		srv[:rules].each do |path, rule|
			rule.gsub! '\n', '\n\t\t' #not working
			fput "\tlocation #{path} {"
			fput "\t\t#{rule}"
			fput "\t}"
		end
	end

	fput "}"
	cput "Finished writing #{name}, moving on"
end


# Write generated confîg to the file
cput "Writing config to #{genginx[:path][:conf]}"
File.open(genginx[:path][:conf], 'w') do |cfg|
	cfg.puts $confstring
end

# Notify user that everything is done
cput "Successfully generated config for #{genginx[:server].count} serverblocks."