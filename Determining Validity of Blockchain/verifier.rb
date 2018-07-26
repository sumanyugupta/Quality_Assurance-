require 'flamegraph'
require_relative 'arg_checker'

Flamegraph.generate('billcoin_flamegraph.html') do
	ac = ArgsChecker::new
	ac.check_args(ARGV)
end