local Ut = require("/cc-ut")

local previousColor = term.getTextColor()
term.setTextColor(colors.green)

local ut = Ut({ verbose = false })

local test = ut.test
local describe = ut.describe

local function assert_equals(value, expected)
  if value ~= expected then
    term.setTextColor(previousColor)
    error('Expected ' .. textutils.serialize(value) .. ' to be ' .. textutils.serialize(expected), 2)
  end
end

local testResult = nil

testResult = test("test passing", function(expect)
  expect(1).toBe(1)
end)
assert_equals(testResult.status, 'passed')
assert_equals(testResult.passed[1], 'Expected 1 to be 1')
print("+ test passing")

testResult = test("test correctly throwing", function(expect)
  expect(function() error("test error") end).toThrow()
end)
assert_equals(testResult.status, 'passed')
assert_equals(testResult.passed[1], 'Expected function to throw an error')
print("+ test correctly throwing")

testResult = test("test failing", function(expect)
  expect(1).toBe(0)
end)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1], 'Expected 1 to be 0')
print("+ test failing")

testResult = test("no expectations set", function(expect)
  return
end)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1], 'No expectations set')
print("+ no expectations set")

testResult = test("test wrongfully throwing", function(expect)
  error("test error")
end)
assert_equals(testResult.status, 'failed')

local function extractErrorMessage(errorString)
  return errorString:match("^.+:%d+:%s*(.+)$")
end

assert_equals(extractErrorMessage(testResult.failed[1]), 'test error')
print("+ test wrongfully throwing")

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
print("+ successful describe")

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
print("+ failed describe")

-- Test hooks
local hookOrder = {}

testResult = describe('testing hooks', function(test)
  local ut = Ut({ verbose = false })

  ut.beforeEach(function()
    table.insert(hookOrder, 'ut before')
  end)

  ut.afterEach(function()
    table.insert(hookOrder, 'ut after')
  end)

  ut.test.beforeEach(function()
    table.insert(hookOrder, 'ut test before')
  end)

  ut.test.afterEach(function()
    table.insert(hookOrder, 'ut test after')
  end)

  ut.describe.beforeEach(function()
    table.insert(hookOrder, 'ut describe before')
  end)

  ut.describe.afterEach(function()
    table.insert(hookOrder, 'ut describe after')
  end)

  -- Run a test to verify test hooks
  ut.test('test hooks', function(expect)
    table.insert(hookOrder, 'test execution')
    expect(true).toBeTruthy()
  end)

  -- Verify test hook order
  local expectedTestOrder = {
    'ut before',
    'ut test before',
    'test execution',
    'ut test after',
    'ut after'
  }

  assert_equals(textutils.serialize(hookOrder), textutils.serialize(expectedTestOrder))

  -- Clear hook order
  hookOrder = {}

  -- Run a describe to verify describe hooks
  ut.describe('describe hooks', function(test)
    test.beforeEach(function()
      table.insert(hookOrder, 'nested test before')
    end)

    test.afterEach(function()
      table.insert(hookOrder, 'nested test after')
    end)

    test('nested test 1', function(expect)
      table.insert(hookOrder, 'nested test 1 execution')
      expect(true).toBeTruthy()
    end)

    test('nested test 2', function(expect)
      table.insert(hookOrder, 'nested test 2 execution')
      expect(true).toBeTruthy()
    end)
  end)

  -- Verify describe hook order
  local expectedDescribeOrder = {
    'ut before',
    'ut describe before',
    'nested test before',
    'nested test 1 execution',
    'nested test after',
    'ut describe after',
    'ut after',
    'ut before',
    'ut describe before',
    'nested test before',
    'nested test 2 execution',
    'nested test after',
    'ut describe after',
    'ut after',
  }

  assert_equals(textutils.serialize(hookOrder), textutils.serialize(expectedDescribeOrder))
end)

print("+ testing hooks")

term.setTextColor(previousColor)
