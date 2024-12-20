local Ut = require("/cc-ut")

local ut = Ut()

local test = ut.test
local describe = ut.describe

ut.beforeEach(function()
	-- This will be run before each test for this ut instance.
end)

ut.afterEach(function()
	-- This will be run after each test for this ut instance.
end)

test.beforeEach(function()
	-- This will be run before each outer test for this ut instance.
end)

test.afterEach(function()
	-- This will be run after each outer test for this ut instance.
end)

test("testing 'to be'", function(expect)
	expect(1).toBe(1)
end)

test("testing 'to throw'", function(expect)
	expect(function() error("test error") end).toThrow()
end)

describe.beforeEach(function()
	-- This will be run before each test within any describe.
end)

describe.afterEach(function()
	-- This will be run after each test within any describe.
end)

describe("testing 'describe'", function(test)
	test.beforeEach(function()
		-- This will be run before each test within this describe.
	end)

	test.afterEach(function()
		-- This will be run after each test within this describe.
	end)

	test("test 1", function(expect)
		expect(1).toBe(1)
		sleep(1)
	end)

	test("test 2", function(expect)
		expect(1).toBe(1)
		sleep(1)
	end)

	test("test 3", function(expect)
		expect(1).toBe(1)
		sleep(1)
	end)
end)

test("this tests fails!", function(expect)
	expect(1).toBe(2)
end)
