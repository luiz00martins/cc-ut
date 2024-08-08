local Ut = require("cc-ut")

local ut = Ut({ verbose = false })

local test = ut.test
local describe = ut.describe

local function assert_equals(value, expected)
  assert(value == expected, 'Expected ' .. textutils.serialize(value) .. ' to be ' .. textutils.serialize(expected))
end

local function printTestResult(result)
  if result.status == 'passed' then
    print('+ ' .. result.name .. ' (' .. #result.passed .. ' passed)')
  else
    print('- ' .. result.name .. ' (' .. #result.failed .. ' failed)')
    for _, failures in ipairs(result.failed) do
      for _, failureMessage in ipairs(failures) do
        print('  - ' .. failureMessage)
      end
    end
  end
end

local testResult = nil

testResult = test("test passing", function(expect)
  expect(1).toBe(1)
end)
printTestResult(testResult)
assert_equals(testResult.status, 'passed')
assert_equals(testResult.passed[1], 'Expected 1 to be 1')

testResult = test("test correctly throwing", function(expect)
  expect(function() error("test error") end).toThrow()
end)
printTestResult(testResult)
assert_equals(testResult.status, 'passed')
assert_equals(testResult.passed[1], 'Expected function to throw an error')

testResult = test("test failing", function(expect)
  expect(1).toBe(0)
end)
printTestResult(testResult)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1], 'Expected 1 to be 0')

testResult = test("no test", function(expect)
  return
end)
printTestResult(testResult)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1], 'No expectations set')

testResult = test("test wrongfully throwing", function(expect)
  error("test error")
end)
printTestResult(testResult)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1], '/cc-ut/test.lua:56: test error')

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
printTestResult(testResult)
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
printTestResult(testResult)
assert_equals(testResult.status, 'failed')
assert_equals(testResult.failed[1].failed[1], 'Expected 1 to be 0')
assert_equals(testResult.failed[2].failed[1], 'No expectations set')