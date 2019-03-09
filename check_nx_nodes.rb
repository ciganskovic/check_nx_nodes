#!/usr/bin/env ruby

require 'getoptlong'

opts = GetoptLong.new(
	[ '--help'     , '-h' , GetoptLong::NO_ARGUMENT ]       ,
	[ '--warning'  , '-w' , GetoptLong::REQUIRED_ARGUMENT ] ,
	[ '--critical' , '-c' , GetoptLong::REQUIRED_ARGUMENT ] ,
)

def usage
	puts <<-EOF

Usage: check_nx_nodes -w limit -c limit

-h, --help:
   show help

-w, --warning:
   Set limit for warning

-c, --critical
   Set limit for critical

	EOF
end

opts.each do |opt, arg|
	case opt
	when '--help'
		usage
	when '--warning'
		@warning = arg.to_i
	when '--critical'
		@critical = arg.to_i
	end

end

def check_nodes

	nodelist = `/usr/NX/bin/nxserver --nodelist | cut -d " " -f 1 | sed '1,3d'`

	if nodelist == ""
		puts 'CRITICAL: Couldn\'t determine the list of nx nodes'
		exit 2
	end

	nodes = nodelist.split(' ')

	counts = Hash.new 0

	nodes.each do |x|
		counts[x] +=1
	end

	max_nodes = counts['running']+counts['unreachable']

	if @warning >= max_nodes
		puts "please choose a value under #{max_nodes} for Warning"
		exit 1
	end

	if @critical > @warning
		puts "please choose a value under #{@warning} for Critical"
		exit 1
	end

	running_nodes = counts['running']

	if running_nodes <= @warning and running_nodes > @critical
		puts "WARNING: Only #{running_nodes} out of #{max_nodes} nodes are running"
		exit 1
	elsif running_nodes <= @critical
		puts "CRITICAL: Only #{running_nodes} out of #{max_nodes} nodes are running"
		exit 2
	else
		puts "OK: #{running_nodes} out of #{max_nodes} nodes are running"
	end
end

if @warning.nil? or @critical.nil?
	puts 'ERROR: Missing commandline arguments'
	puts
	exit 0
else
	check_nodes
end
