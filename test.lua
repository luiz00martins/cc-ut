local Ut = require("cc-ut")

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

term.setTextColor(previousColor)
