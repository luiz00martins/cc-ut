local ut = require("/cc-ut")

local test = ut.test
local describe = ut.describe

test("testing to be", function(expect)
	expect(1).toBe(1)
end)

test("test throw", function(expect)
	expect(function() error("test error") end).toThrow()
end)

describe('describe', function(test)
	test("test 1", function(expect)
		expect(1).toBe(1)
	end)

	test("test 2", function(expect)
		expect(1).toBe(1)
	end)

	test("test 3", function(expect)
		expect(1).toBe(1)
	end)
end)
