---@alias ExpectFunction fun(value: any): Expectation
---@alias TestBlock fun(expect: ExpectFunction)
---@alias DescribeBlock fun(test: fun(testName: string, func: TestBlock))
---@alias TestFunction fun(testName: string, block: TestBlock): TestResult
---@alias DescribeFunction fun(description: string, block: DescribeBlock): DescribeResult

---@class Expectation
---@field toBe fun(expected: any): Expectation
---@field toEqual fun(expected: any): Expectation
---@field toThrow fun(): Expectation
---@field toContain fun(expected: any): Expectation
---@field toBeTruthy fun(): Expectation

---@class UtInstance
---@field test TestFunction
---@field describe DescribeFunction

---@class TestResult
---@field name string
---@field status "passed"|"failed"
---@field failed? string[]
---@field passed? string[]

---@class DescribeResult
---@field name string
---@field status "passed"|"failed"
---@field failed TestResult[]
---@field passed TestResult[]

local utils = require('/cc-ut/utils')

local table_compare_by_value = utils.table_compare_by_value

---Utility to compare values and print results with colors
---@param args {testName: string, failed?: string[], indent?: string, verbose?: boolean}
local function printResult(args)
  local testName = args.testName
  local failed = args.failed or {}
  local indent = args.indent or ""
  local verbose = args.verbose ~= false -- Default to true if not specified

  if not verbose then return end

  local original_color = term.getTextColor()

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

  term.setTextColor(original_color)
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

---@param onTest fun(testName: string, result: TestResult)
---@return fun(testName: string, block: TestBlock): TestResult
local function createTestFunction(onTest)
  return function(testName, block)
    if not block then
      error('No function provided')
    end

    local expectation = createExpectation(false, nil, nil)
    local success, err = pcall(block, expectation.expect)

    local result
    if not success then
      result = {
        name = testName,
        status = 'failed',
        failed = {err},
      }
    elseif not expectation.evaluated then
      local error_message = 'No expectations set'
      result = {
        name = testName,
        status = 'failed',
        failed = {error_message},
      }
    else
      if #expectation.failed > 0 then
        result = {
          name = testName,
          status = 'failed',
          failed = expectation.failed,
        }
      else
        result = {
          name = testName,
          status = 'passed',
          passed = expectation.passed,
        }
      end
    end

    if onTest then
      onTest(testName, result)
    end

    return result
  end
end

---@param config {verbose?: boolean}
---@return UtInstance
local function create_instance(config)
  config = config or {}
  local verbose = config.verbose ~= false -- Default to true if not specified

  ---@type TestFunction
  local function test(testName, block)
    local testFunction = createTestFunction(function(_testName, result)
      printResult{testName = _testName, failed = result.failed, verbose = verbose}
    end)

    return testFunction(testName, block)
  end

  ---@type DescribeFunction
  local function describe(description, block)
    if not block then
      error('No block provided')
    end

    local original_color = term.getTextColor()
    local tests = {}
    local failed = {}
    local passed = {}

    if verbose then
      term.setTextColor(colors.blue)
      print('* ' .. description)
    end

    local localTest = createTestFunction(function(testName, result)
      if result.status == 'failed' then
        table.insert(failed, result)
      else
        table.insert(passed, result)
      end
      table.insert(tests, result)

      if verbose then
        -- Update progress bar
        term.setCursorPos(1, select(2, term.getCursorPos()))
        term.clearLine()
        term.write('  * ' .. testName)
      end
    end)

    block(localTest)

    if verbose then
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
          printResult{testName = test.name, failed = test.failed, verbose = verbose}
        end
      end

      term.setTextColor(original_color)
    end

    return {
      name = description,
      status = #failed > 0 and 'failed' or 'passed',
      failed = failed,
      passed = passed,
    }
  end

  ---@type UtInstance
  local instance = {
    test = test,
    describe = describe
  }

  return instance
end

return create_instance
