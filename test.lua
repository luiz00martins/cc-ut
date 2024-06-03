local ut = require("cc-ut")

local test = ut.test
local describe = ut.describe

local function assert_equals(value, expected)
	assert(value == expected, 'Expected ' .. textutils.serialize(value) .. ' to be ' .. textutils.serialize(expected))
end

local testResult = nil

testResult = test("test passing", function(expect)
	expect(1).toBe(1)
end)
assert_equals(testResult.status, 'passed')
assert_equals(testResult.passed[1], 'Expected 1 to be 1')

testResult = test("test correctly throwing", function(expect)
	expect(function() error("test error") end).toThrow()
end)
assert_equals(testResult.status, 'passed')
assert_equals(testResult.passed[1], 'Expected function to throw an error')

testResult = test("test failing", function(expect)
	expect(1).toBe(0)
end)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1], 'Expected 1 to be 0')

testResult = test("no test", function(expect)
	return
end)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1], 'No expectations set')

testResult = test("test wrongfully throwing", function(expect)
	error("test error")
end)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1], 'test.lua:49: test error')

testResult = describe('successful describe', function(test)
	test("matching 1", function(expect)
		expect(1).toBe(1)
	end)

	test("matching 2", function(expect)
		expect(1).toBe(1)
	end)

	test("matching 3", function(expect)
		expect(1).toBe(1)
	end)
end)
assert_equals(testResult.status, 'passed')
assert_equals(testResult.passed[1].passed[1], 'Expected 1 to be 1')
assert_equals(testResult.passed[2].passed[1], 'Expected 1 to be 1')
assert_equals(testResult.passed[3].passed[1], 'Expected 1 to be 1')

testResult = describe('failed describe', function(test)
	test("wrong value", function(expect)
		expect(1).toBe(0)
	end)

	test("no expectation", function(expect)
	end)
end)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1].failed[1], 'Expected 1 to be 0')
assert_equals(testResult.failed[2].failed[1], 'No expectations set')
