---@alias ExpectFunction fun(value: any): Expectation
---@alias TestFunction fun(expect: ExpectFunction)
---@alias TestBlock fun(test: fun(testName: string, func: TestFunction))

---@class Expectation
---@field toBe fun(expected: any): Expectation
---@field toEqual fun(expected: any): Expectation
---@field toThrow fun(): Expectation
---@field toContain fun(expected: any): Expectation
---@field toBeTruthy fun(): Expectation

---@class UtInstance
---@field test fun(testName: string, func: TestFunction): TestResult
---@field describe fun(description: string, block: TestBlock): DescribeResult

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

local function create_instance(config)
  config = config or {}
  local verbose = config.verbose ~= false  -- Default to true if not specified

  -- Utility to compare values and print results with colors
  local function printResult(testName, failed, indent)
    local original_color = term.getTextColor()

    if not verbose then return end
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

  local function createTestFunction(onTest)
    return function(testName, func)
      if not func then
        error('No function provided')
      end

      local expectation = createExpectation(false, nil, nil)
      local success, err = pcall(func, expectation.expect)

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

  local function test(testName, func)
    return createTestFunction(function(testName, result)
      printResult(testName, result.failed or {})
    end)(testName, func)
  end

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
          printResult(test.name, test.failed, '  ')
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
