local utils = require('cc-ut.utils')

local table_compare_by_value = utils.table_compare_by_value

-- Utility to compare values and print results with colors
local function printResult(testName, failed, indent)
  indent = indent or ""
  if #failed == 0 then
    term.setTextColor(colors.green)
    print(indent .. '+ ' .. testName)
  else
    for _, errorMessage in ipairs(failed) do
      if errorMessage == 'No expectations set' then
        term.setTextColor(colors.yellow)
        print(indent .. '* ' .. testName .. ': ' .. errorMessage)
      else
        term.setTextColor(colors.red)
        print(indent .. '- ' .. testName .. ': ' .. errorMessage)
      end
    end
  end
  term.setTextColor(colors.white)
end

local function createExpectation(evaluated, passed, failed)
	local expectation = {
		evaluated = evaluated,
		passed = passed or {},
		failed = failed or {}
	}

	local expect = function(value)
		local self = {}

		function self.toBe(expected)
			expectation.evaluated = true
			if value ~= expected then
				table.insert(expectation.failed, 'Expected ' .. tostring(value) .. ' to be ' .. tostring(expected))
				return self
			end
			table.insert(expectation.passed, 'Expected ' .. tostring(value) .. ' to be ' .. tostring(expected))
			return self
		end

		function self.toEqual(expected)
			expectation.evaluated = true
			if not table_compare_by_value(value, expected) then
				table.insert(expectation.failed, 'Expected ' .. tostring(value) .. ' to equal ' .. tostring(expected))
				return self
			end
			table.insert(expectation.passed, 'Expected ' .. tostring(value) .. ' to equal ' .. tostring(expected))
			return self
		end

		function self.toThrow()
			expectation.evaluated = true
			local success, result = pcall(value)
			if success then
				table.insert(expectation.failed, 'Expected function to throw an error')
				return self
			end
			table.insert(expectation.passed, 'Expected function to throw an error')
			return self
		end

		function self.toContain(expected)
			expectation.evaluated = true
			if not utils.table_contains(value, expected) then
				table.insert(expectation.failed, 'Expected ' .. tostring(value) .. ' to contain ' .. tostring(expected))
				return self
			end
			table.insert(expectation.passed, 'Expected ' .. tostring(value) .. ' to contain ' .. tostring(expected))
			return self
		end

		function self.toBeTruthy()
			expectation.evaluated = true
			if not value then
				table.insert(expectation.failed, 'Expected ' .. tostring(value) .. ' to be truthy')
				return self
			end
			table.insert(expectation.passed, 'Expected ' .. tostring(value) .. ' to be truthy')
			return self
		end

		return self
	end

	expectation.expect = expect

	return expectation
end

-- Test function that runs a test case
local function test(testName, func)
	if not func then
		error('No function provided')
	end

	local expectation = createExpectation(false, nil, nil)

	local success, err = pcall(func, expectation.expect)

	if not success then
		printResult(testName, {err})
		return {
			status = 'failed',
			failed = {err},
		}
	elseif not expectation.evaluated then
		local error_message = 'No expectations set'
		printResult(testName, {error_message})
		return {
			status = 'failed',
			failed = {error_message},
		}
	else
		printResult(testName, expectation.failed)

		if #expectation.failed > 0 then
			return {
				status = 'failed',
				failed = expectation.failed,
			}
		else
			return {
				status = 'passed',
				passed = expectation.passed,
			}
		end
	end
end

-- Describe block to group and execute tests
local function describe(description, block)
	if not block then
		error('No block provided')
	end

	local tests = {}
	local failed = {}
	local passed = {}

	local function localTest(testName, func)
		table.insert(tests, {name = testName, func = func})
	end

	block(localTest)

	-- Initial output
	print(description)
	term.write('Running tests: [' .. string.rep(' ', 10) .. '] (0/' .. #tests .. ')')

	for i, test in ipairs(tests) do
		local expectation = createExpectation(false, nil, nil)
		local success, err = pcall(test.func, expectation.expect)
		if not success then
			expectation.failed = {err}
		elseif not expectation.evaluated then
			expectation.failed = {'No expectations set'}
			success = false
		else
			success = #expectation.failed == 0
		end

		if not success then
			table.insert(failed, {
				name = test.name,
				failed = expectation.failed,
			})
		else
			table.insert(passed, {
				name = test.name,
				passed = expectation.passed,
			})
		end

		-- Update progress bar
		term.setCursorPos(1, select(2, term.getCursorPos()) - 1)
		term.clearLine()
		term.write('. ' .. description)
		term.setCursorPos(1, select(2, term.getCursorPos()) + 1)
		term.clearLine()
		local progress = math.floor((i / #tests) * 10)
		term.write('Running tests: [' .. string.rep('#', progress) .. string.rep(' ', 10 - progress) .. '] (' .. i .. '/' .. #tests .. ')')
	end

	-- Clear lines for final message
	term.setCursorPos(1, select(2, term.getCursorPos()) - 1)
	term.clearLine()
	term.setCursorPos(1, select(2, term.getCursorPos()) + 1)
	term.clearLine()
	term.setCursorPos(1, select(2, term.getCursorPos()) - 1)

	-- Final message
	if #failed == 0 then
		term.setTextColor(colors.green)
		print('+ ' .. description .. ' (' .. #passed .. '/' .. #tests .. ')')
	else
		term.clearLine()
		term.setTextColor(colors.red)
		print('- ' .. description .. ' (' .. #passed .. '/' .. #tests .. ')')
		for _, test in ipairs(failed) do
			printResult(test.name, test.failed, '  ')
		end
	end

	term.setTextColor(colors.white)

	return {
		status = #failed > 0 and 'failed' or 'passed',
		failed = failed,
		passed = passed,
	}
end

return {
	test = test,
	describe = describe
}

