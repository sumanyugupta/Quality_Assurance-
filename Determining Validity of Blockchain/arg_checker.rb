# Class that checks the file argument provided by user.

class ArgsChecker
	@billcoins = Hash.new
	def check_args(arr)
		if arr.count != 1
			puts "Enter only one file please!"
			abort
		end

		target_dir = "DeliverableFiles/TestFiles"
		begin
			Dir.chdir(target_dir)
		rescue SystemCallError
			puts "Make sure you have the correct directories."
			abort
		end
		all_files = Dir.glob("*")

		if all_files.include? arr[0]
			all_lines = File.readlines(arr[0])
		else
			puts "Sorry, that file does not exist. Please make sure your file is in the ./DeliverableFiles/TestFiles directory with the correct extension."
			abort
		end

		value = check_block_number(all_lines)
		check_value(value)
		value = check_block_zero_transaction_count(all_lines[0])
		check_value(value)
		value = check_timestamp(all_lines)
		check_value(value)
		
		all_hashed_lines = []
		for i in 0..all_lines.length-1
			value = check_line_elements(all_lines[i])
			check_value(value)
			value = check_transaction_format(all_lines[i])
			check_value(value)
			if i == 0
				value = check_block_zero_previous_hash(all_lines[i])
				check_value(value)
			else
				value = check_previous_hash(all_lines[i], all_lines[i - 1])
				check_value(value)
			end
			all_hashed_lines[i] = compute_hash(all_lines[i])
			check_value(all_hashed_lines[i])
			value = check_computed_hash(all_lines[i], all_hashed_lines[i])
			check_value(value)
			value = check_transactions_per_block(all_lines[i])
			check_value(value)
			value = get_transactions(all_lines[i])
			check_value(value)
		end

		@billcoins.each {|key, value| puts "#{key}: #{value} billcoins"}

		target_dir = "../.."
		Dir.chdir(target_dir)
	end
	
	def check_value(value)
		if value == "BLOCKCHAIN INVALID"
			abort
		end
	end
	
	def check_line_elements(line)
		line = line.split("|")
		if not line.length == 5
			puts "Line #{line[0]}: Has #{line.length} elements, should have 5 elements."
			puts "BLOCKCHAIN INVALID"
			return "BLOCKCHAIN INVALID"
		end
		line.length
	end
		
	def check_block_number(lines)
		for i in 0..lines.length-1
			if lines[i].split("|")[0].to_i != i
				puts "Line #{i}: Invalid block number #{lines[i][0]}, should be #{i}."
				puts "BLOCKCHAIN INVALID"
				return "BLOCKCHAIN INVALID"
			end
		end
		lines.length
	end

	def compute_hash(line)
		str_to_hash = line.split("|").slice(0, 4).join("|")
		hashed = (str_to_hash.unpack("U*").map { |x| (x ** 2000) * ((x + 2) ** 21) - ((x + 5) ** 3) }.sum() % 65536).to_s(16)
		hashed
	end
	
	def check_computed_hash(line, real_hash)
		line_minus_hash = line.split("|").slice(0, 4).join("|")
		line = line.split("|")
		line_hash = line[4].strip
		if not real_hash.eql? line_hash
			puts "Line #{line[0]}: String '#{line_minus_hash}' hash set to #{line_hash}, should be #{real_hash}."
			puts "BLOCKCHAIN INVALID"
			return "BLOCKCHAIN INVALID"
		end
		line_hash
	end
	
	def check_previous_hash(current_line, previous_line)
		current_line = current_line.split("|")
		previous_line = previous_line.split("|")
		if current_line[1] != previous_line[4].strip
			puts "Line #{current_line[0]}: Previous hash was #{current_line[1]}, should be #{previous_line[4].strip}."
			puts "BLOCKCHAIN INVALID"
			return "BLOCKCHAIN INVALID"
		end
		current_line[1]
	end
	
	def check_block_zero_previous_hash(line)
		line = line.split("|")
		if line[1] != 0.to_s
			puts "Line #{line[0]}: Previous hash was #{line[1]}, should be 0."
			puts "BLOCKCHAIN INVALID"
			return "BLOCKCHAIN INVALID"
		end
		0
	end

	def check_block_zero_transaction_count(line)
		num_transacs = line.scan(/\>/).count
		if num_transacs != 1
			puts "Line #{line[0]}: Block 0 contains #{num_transacs} transactions, should be 1."
			puts "BLOCKCHAIN INVALID"
			return "BLOCKCHAIN INVALID"
		end
		num_transacs
	end

	def check_transactions_per_block(line)
		num_transacs = line.scan(/\>/).count
		if num_transacs < 1
			puts "Line #{line[0]}: Block #{line[0]} contains #{num_transacs} transactions, should be at least 1."
			puts "BLOCKCHAIN INVALID"
			return "BLOCKCHAIN INVALID"
		end
		num_transacs
	end
	
	def check_transaction_format(line)
		line = line.split("|")
		match_data = line[2].match(/([[A-Za-z]]{0,6}>[[A-Za-z]]{0,6}\([0-9]+\):)*SYSTEM>[[A-Za-z]]{0,6}\([[0-9]]+\)/)
		
		if match_data.nil? || line[2] != match_data[0]
			multiple_transactions = line[2].split(":")
			for i in 0..multiple_transactions.length-1
				giver = multiple_transactions[i].split(">")
				receiver = giver[1].split("(")
				giver_match = giver[0].match(/[[A-Za-z]]{0,6}/)
				receiver_match = receiver[0].match(/[[A-Za-z]]{0,6}/)
				if giver_match.nil? || giver[0] != giver_match[0]
					puts "Line #{line[0]}: #{giver[0]} is an invalid address."
					puts "BLOCKCHAIN INVALID"
					return "BLOCKCHAIN INVALID"
				end
				if receiver_match.nil? || receiver[0] != receiver_match[0]
					puts "Line #{line[0]}: #{receiver[0]} is an invalid address."
					puts "BLOCKCHAIN INVALID"
					return "BLOCKCHAIN INVALID"
				end
				if i == multiple_transactions.length-1 && giver[0] != "SYSTEM"
					puts "Line #{line[0]}: The final transaction is not from SYSTEM."
					puts "BLOCKCHAIN INVALID"
					return "BLOCKCHAIN INVALID"
				end
			end
			puts "Line #{line[0]}: #{line[2]} contains a transaction with incorrect formatting."
			puts "BLOCKCHAIN INVALID"
			return "BLOCKCHAIN INVALID"
		end
		line[2]
	end

	def get_transactions(line)
		addresses_used = Hash.new
		transaction = line.split("|")[2]
		multiple_transactions = []
		multiple_transactions = transaction.split(":")
		for i in 0..multiple_transactions.length-1
			giver = multiple_transactions[i].split(">")
			receiver = giver[1].split("(")
			number_of_coins = receiver[1].split(")")

			if not giver[0] == "SYSTEM"
				if not addresses_used.has_key?(giver[0])
					addresses_used[giver[0]] = 0
				end
			end

			if not addresses_used.has_key?(receiver[0])
				addresses_used[receiver[0]] = 0
			end

			if @billcoins.nil?
				@billcoins = Hash.new
			end

			if not giver[0] == "SYSTEM"
				if not @billcoins.has_key?(giver[0])
					@billcoins[giver[0]] = 0
				end
				@billcoins[giver[0]] = Integer(@billcoins[giver[0]]) - Integer(number_of_coins[0])
			end

			if not @billcoins.has_key?(receiver[0])
				@billcoins[receiver[0]] = 0
			end
			@billcoins[receiver[0]] = Integer(@billcoins[receiver[0]]) + Integer(number_of_coins[0])
		end

		addresses_used = addresses_used.keys
		for i in 0..addresses_used.length-1
			if @billcoins[addresses_used[i]] < 0
				puts "Line #{line.split("|")[0]}: Invalid block, address #{addresses_used[i]} has #{@billcoins[addresses_used[i]]} billcoins!"
				puts "BLOCKCHAIN INVALID"
				return "BLOCKCHAIN INVALID"
			end
		end
		addresses_used
	end
	
	def check_timestamp(all_lines)
		seconds = []
		nanoseconds = []

		for i in 0..all_lines.length-1
			# Check there is only one period in the timestamp.
			num_periods = all_lines[i].split("|")[3].scan(/\./).count

			if num_periods != 1
				puts "Line #{all_lines[i].split("|")[0]}: Timestamp contains #{num_periods} periods, should be 1."
				puts "BLOCKCHAIN INVALID"
				return "BLOCKCHAIN INVALID"
			end

			# Check that the seconds and nanoseconds values are valid values.
			begin
				seconds[i] = Float(all_lines[i].split("|")[3].split(".")[0])
				nanoseconds[i] = Integer(all_lines[i].split("|")[3].split(".")[1])
			rescue ArgumentError
				puts "Line #{all_lines[i].split("|")[0]}: Timestamp is not valid because #{all_lines[i].split("|")[3]} is not a valid timestamp value."
				puts "BLOCKCHAIN INVALID"
				return "BLOCKCHAIN INVALID"
			end

			nanoseconds[i] =  Float(nanoseconds[i] * (10 ** -9))
			seconds[i] = seconds[i] + nanoseconds[i]
		end

		times = seconds.each_cons(2).to_a
		for i in 0..times.length-1
			if times[i][0].to_f >= times[i][1].to_f
				puts "Line #{all_lines[i+1].split("|")[0]}: Previous timestamp #{times[i][0].to_s << '000'} >= new timestamp #{times[i][1].to_s << '000'}."
				puts "BLOCKCHAIN INVALID"
				return "BLOCKCHAIN INVALID"
			end
		end
		seconds.length
	end
end