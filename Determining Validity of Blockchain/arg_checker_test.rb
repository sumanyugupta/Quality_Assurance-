require 'minitest/autorun'
require_relative 'arg_checker'

class ArgsCheckerTest < Minitest::Test

	def setup
		@args_checker = ArgsChecker::new
	end


	def test_timestamp_too_many_periods
		test_line1 = "52|58af|SYSTEM>Mzila(100)|1518893687.90593600.0|4ec6"
		test_line2 = "53|4ec6|Mary>Kublai(16):SYSTEM>Peter(100)|1518893687.909664000|4b60"
		test_lines = [test_line1, test_line2]
		assert_output("Line 52: Timestamp contains 2 periods, should be 1.\nBLOCKCHAIN INVALID\n") {@args_checker.check_timestamp(test_lines)}
		assert_equal(@args_checker.check_timestamp(test_lines),"BLOCKCHAIN INVALID")
	end
	
	def test_timestamp_too_few_periods
		test_line1 = "52|58af|SYSTEM>Mzila(100)|1518893687905936000|4ec6"
		test_line2 = "53|4ec6|Mary>Kublai(16):SYSTEM>Peter(100)|1518893687.909664000|4b60"
		test_lines = [test_line1, test_line2]
		assert_output("Line 52: Timestamp contains 0 periods, should be 1.\nBLOCKCHAIN INVALID\n") {@args_checker.check_timestamp(test_lines)}
		assert_equal(@args_checker.check_timestamp(test_lines),"BLOCKCHAIN INVALID")
	end
	
	def test_bad_timestamp_values
		test_line1 = "52|58af|SYSTEM>Mzila(100)|15188fasdf687.905936000|4ec6"
		test_line2 = "53|4ec6|Mary>Kublai(16):SYSTEM>Peter(100)|1518893687.909664000|4b60"
		test_lines = [test_line1, test_line2]
		assert_output("Line 52: Timestamp is not valid because 15188fasdf687.905936000 is not a valid timestamp value.\nBLOCKCHAIN INVALID\n") {@args_checker.check_timestamp(test_lines)}
		assert_equal(@args_checker.check_timestamp(test_lines),"BLOCKCHAIN INVALID")
	end

	def test_bad_seconds_timestamp
		test_line1 = "7|949|Louis>Louis(1):George>Edward(15):Sheba>Wu(1):Henry>James(12):Amina>Pakal(22):SYSTEM>Kublai(100)|1518892053.799497000|f944"
		test_line2 = "8|f944|SYSTEM>Tang(100)|1518892051.812065000|775a"
		test_lines = [test_line1, test_line2]
		assert_output("Line 8: Previous timestamp 1518892053.799497000 >= new timestamp 1518892051.812065000.\nBLOCKCHAIN INVALID\n") {@args_checker.check_timestamp(test_lines)}
		assert_equal(@args_checker.check_timestamp(test_lines),"BLOCKCHAIN INVALID")
	end
	
	def test_bad_nanoseconds_timestamp
		test_line1 = "6|d072|Wu>Edward(16):SYSTEM>Amina(100)|1518892051.793695000|949"
		test_line2 = "7|949|Louis>Louis(1):George>Edward(15):Sheba>Wu(1):Henry>James(12):Amina>Pakal(22):SYSTEM>Kublai(100)|1518892051.199497000|1e5c"
		test_lines = [test_line1, test_line2]
		assert_output("Line 7: Previous timestamp 1518892051.793695000 >= new timestamp 1518892051.199497000.\nBLOCKCHAIN INVALID\n") {@args_checker.check_timestamp(test_lines)}
		assert_equal(@args_checker.check_timestamp(test_lines),"BLOCKCHAIN INVALID")
	end
	
	def test_good_timestamp
		test_line1 = "52|58af|SYSTEM>Mzila(100)|1518893687.905936000|4ec6"
		test_line2 = "53|4ec6|Mary>Kublai(16):SYSTEM>Peter(100)|1518893687.909664000|4b60"
		test_lines = [test_line1, test_line2]
		assert_output("") {@args_checker.check_timestamp(test_lines)}
		assert_equal(@args_checker.check_timestamp(test_lines), 2)
	end
	
	def test_good_transaction
		test_line = "0|0|Bob>Sam(5):SYSTEM>Bob(100)|1518893687.329767000|fd18"
		assert_output("") {@args_checker.get_transactions(test_line)}
		assert_equal(@args_checker.get_transactions(test_line), ["Bob", "Sam"])
	end
	
	def test_negative_transaction
		test_line = "0|0|Bob>Sam(5):SYSTEM>Gaozu(100)|1518893687.329767000|fd18"
		assert_output("Line 0: Invalid block, address Bob has -5 billcoins!\nBLOCKCHAIN INVALID\n") {@args_checker.get_transactions(test_line)}
		assert_equal(@args_checker.get_transactions(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_too_many_elements
		test_line = "0|0|SYSTEM>Gaozu(100)|1518893687.329767000|fd18|boo"
		assert_output("Line 0: Has 6 elements, should have 5 elements.\nBLOCKCHAIN INVALID\n") {@args_checker.check_line_elements(test_line)}
		assert_equal(@args_checker.check_line_elements(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_too_few_elements
		test_line=""
		assert_output("Line : Has 0 elements, should have 5 elements.\nBLOCKCHAIN INVALID\n") {@args_checker.check_line_elements(test_line)}
		assert_equal(@args_checker.check_line_elements(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_correct_elements
		test_line = "0|0|SYSTEM>Gaozu(100)|1518893687.329767000|fd18"
		assert_output("") {@args_checker.check_line_elements(test_line)}
		assert_equal(@args_checker.check_line_elements(test_line), 5)
	end
	
	def test_block_zero_too_many_transactions
		test_line = "0|97df|Henry>Edward(23):Rana>Alfred(1):James>Rana(1):SYSTEM>George(100)|1518892051.783448000|d072"
		expected_output = "Line 0: Block 0 contains 4 transactions, should be 1.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_block_zero_transaction_count(test_line)}
		assert_equal(@args_checker.check_block_zero_transaction_count(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_block_zero_too_few_transactions
		test_line = "0|97df||1518892051.783448000|d072"
		expected_output = "Line 0: Block 0 contains 0 transactions, should be 1.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_block_zero_transaction_count(test_line)}
		assert_equal(@args_checker.check_block_zero_transaction_count(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_block_zero_correct_transactions
		test_line = "0|0|SYSTEM>Henry(100)|1518892051.737141000|1c12"
		expected_output = ""
		assert_output(expected_output) {@args_checker.check_block_zero_transaction_count(test_line)}
		assert_equal(@args_checker.check_block_zero_transaction_count(test_line), 1)
	end
	
	def test_nonzero_block_too_few_transactions
		test_line = "1|1c12||1518892051.740967000|abb2"
		expected_output = "Line 1: Block 1 contains 0 transactions, should be at least 1.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_transactions_per_block(test_line)}
		assert_equal(@args_checker.check_transactions_per_block(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_nonzero_block_correct_number_of_transactions
		test_line = "9|775a|Henry>Pakal(10):SYSTEM>Amina(100)|1518892051.815834000|2d7f"
		expected_output = ""
		assert_output(expected_output) {@args_checker.check_transactions_per_block(test_line)}
		assert_equal(@args_checker.check_transactions_per_block(test_line), 2)
	end

	def test_correctly_computed_hash
		test_line = "9|775a|Henry>Pakal(10):SYSTEM>Amina(100)|1518892051.815834000|2d7f"
		expected_output = "2d7f"
		observed_output = @args_checker.compute_hash(test_line)
		assert_equal observed_output, expected_output
	end

	def test_incorrectly_computed_hash
		test_line = "5|97df|Henry>Edward(23):Rana>Alfred(1):James>Rana(1):SYSTEM>George(100)|1518892051.783448000|d072"
		incorrect_output = "sug27"
		observed_output = @args_checker.compute_hash(test_line)
		refute_equal observed_output, incorrect_output
	end

	def test_incorrect_previous_hash
		cur_line = "8|32aa|SYSTEM>Tang(100)|1518892051.812065000|775a"
		prev_line = "7|949|Louis>Louis(1):George>Edward(15):Sheba>Wu(1):Henry>James(12):Amina>Pakal(22):SYSTEM>Kublai(100)|1518892051.799497000|9895z"
		expected_output = "Line 8: Previous hash was 32aa, should be 9895z.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_previous_hash(cur_line, prev_line)}
		assert_equal(@args_checker.check_previous_hash(cur_line, prev_line), "BLOCKCHAIN INVALID")
	end

	def test_correct_previous_hash
		cur_line = "4|7419|Kublai>Pakal(1):Henry>Peter(10):Cyrus>Amina(3):Peter>Sheba(1):Cyrus>Louis(1):Pakal>Kaya(1):Amina>Tang(4):Kaya>Xerxes(1):SYSTEM>Amina(100)|1518892051.768449000|97df"
		prev_line = "3|c72d|SYSTEM>Henry(100)|1518892051.764563000|7419"
		expected_output = ""
		assert_output(expected_output) {@args_checker.check_previous_hash(cur_line, prev_line)}
		assert_equal(@args_checker.check_previous_hash(cur_line, prev_line), "7419")
	end

	def test_correct_block_zero_hash
		test_line = "0|0|SYSTEM>Louis(100)|1518892464.146158000|728c"
		expected_output = ""
		assert_output(expected_output) {@args_checker.check_block_zero_previous_hash(test_line)}
		assert_equal(@args_checker.check_block_zero_previous_hash(test_line), 0)
	end

	def test_incorrect_block_zero_hash
		test_line = "0|abc123|SYSTEM>Gaozu(100)|1518893687.329767000|fd18"
		expected_output = "Line 0: Previous hash was abc123, should be 0.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_block_zero_previous_hash(test_line)}
		assert_equal(@args_checker.check_block_zero_previous_hash(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_correct_check_computed_hash
		test_line = "0|0|SYSTEM>Louis(100)|1518892464.146158000|728c"
		hash = "728c"
		expected_output = ""
		assert_output(expected_output) {@args_checker.check_computed_hash(test_line, hash)}
		assert_equal(@args_checker.check_computed_hash(test_line, hash), "728c")
	end
	
	def test_incorrect_check_computed_hash
		test_line = "0|0|SYSTEM>Louis(100)|1518892464.146158000|728d"
		hash = "728c"
		expected_output = "Line 0: String '0|0|SYSTEM>Louis(100)|1518892464.146158000' hash set to 728d, should be 728c.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_computed_hash(test_line, hash)}
		assert_equal(@args_checker.check_computed_hash(test_line, hash), "BLOCKCHAIN INVALID")
	end
	
	def test_correct_block_number
		test_line1 = "0|0|SYSTEM>Henry(100)|1518892051.737141000|1c12"
		test_line2 = "1|1c12|SYSTEM>George(100)|1518892051.740967000|abb2"
		test_lines = [test_line1, test_line2]
		expected_output = ""
		assert_output(expected_output) {@args_checker.check_block_number(test_lines)}
		assert_equal(@args_checker.check_block_number(test_lines), 2)
	end
	
	def test_incorrect_block_number
		test_line1 = "0|0|SYSTEM>Henry(100)|1518892051.737141000|1c12"
		test_line2 = "5|1c12|SYSTEM>George(100)|1518892051.740967000|abb2"
		test_lines = [test_line1, test_line2]
		expected_output = "Line 1: Invalid block number 5, should be 1.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_block_number(test_lines)}
		assert_equal(@args_checker.check_block_number(test_lines), "BLOCKCHAIN INVALID")
	end
	
	def test_correct_transaction_format
		test_line = "1|2341|Bob>Sam(100):SYSTEM>Louis(100)|1518892464.146158000|728d"
		expected_output = ""
		assert_output(expected_output) {@args_checker.check_transaction_format(test_line)}
		assert_equal(@args_checker.check_transaction_format(test_line), "Bob>Sam(100):SYSTEM>Louis(100)")
	end
	
	def test_incorrect_transaction_format
		test_line = "1|2341|Bob>Sam(100fff):SYSTEM>Louis(100)|1518892464.146158000|728d"
		expected_output = "Line 1: Bob>Sam(100fff):SYSTEM>Louis(100) contains a transaction with incorrect formatting.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_transaction_format(test_line)}
		assert_equal(@args_checker.check_transaction_format(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_transaction_invalid_from_address_too_long
		test_line = "1|2341|Bobbobbob>Sam(100):SYSTEM>Louis(100)|1518892464.146158000|728d"
		expected_output = "Line 1: Bobbobbob is an invalid address.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_transaction_format(test_line)}
		assert_equal(@args_checker.check_transaction_format(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_transaction_invalid_to_address_nonalphabetic
		test_line = "1|2341|Bob>Sam2(100):SYSTEM>Louis(100)|1518892464.146158000|728d"
		expected_output = "Line 1: Sam2 is an invalid address.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_transaction_format(test_line)}
		assert_equal(@args_checker.check_transaction_format(test_line), "BLOCKCHAIN INVALID")
	end
	
	def test_transaction_system_not_last
		test_line = "1|2341|Bob>Sam(100):Sam>Louis(100)|1518892464.146158000|728d"
		expected_output = "Line 1: The final transaction is not from SYSTEM.\nBLOCKCHAIN INVALID\n"
		assert_output(expected_output) {@args_checker.check_transaction_format(test_line)}
		assert_equal(@args_checker.check_transaction_format(test_line), "BLOCKCHAIN INVALID")
	end
end