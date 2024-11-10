---@alias ExpectFunction fun(value: any): Expectation
---@alias TestBlock fun(expect: ExpectFunction)
---@alias DescribeBlock fun(test: TestInstance)
---@alias TestFunction fun(testName: string, block: TestBlock): TestResult
---@alias DescribeFunction fun(description: string, block: DescribeBlock): DescribeResult
---@alias TestMetaCall fun(self: TestInstance, testName: string, block: TestBlock): TestResult
---@alias DescribeMetaCall fun(self: DescribeInstance, description: string, block: DescribeBlock): DescribeResult

---@class Expectation
---@field toBe fun(expected: any): Expectation
---@field toEqual fun(expected: any): Expectation
---@field toThrow fun(): Expectation
---@field toContain fun(expected: any): Expectation
---@field toBeTruthy fun(): Expectation

---@class TestInstance
---@field beforeEach fun(hook: function)
---@field afterEach fun(hook: function)
---@overload fun(testName: string, block: TestBlock): TestResult

---@class DescribeInstance
---@field beforeEach fun(hook: function)
---@field afterEach fun(hook: function)
---@overload fun(description: string, block: DescribeBlock): DescribeResult

---@class UtInstance
---@field test TestInstance
---@field describe DescribeInstance
---@field beforeEach fun(hook: function)
---@field afterEach fun(hook: function)

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

---@alias Hook fun()

---@class InstanceHooks
---@field before Hook[]
---@field after Hook[]

local utils = require('/cc-ut/utils')

local table_compare_by_value = utils.table_compare_by_value
local array_concat = utils.array_concat

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

---@param hooks Hook[]
local function runHooks(hooks)
  for _, hook in ipairs(hooks) do
    hook()
  end
end

---@param args {onTest?: fun(testName: string, result: TestResult), ut_hooks?: InstanceHooks, test_hooks?: InstanceHooks}
---@return fun(testName: string, block: TestBlock): TestResult
local function createTestFunction(args)
  local onTest = args.onTest
  local ut_hooks = args.ut_hooks or {
    before = {},
    after = {},
  }
  local test_hooks = args.test_hooks or {
    before = {},
    after = {},
  }

  return function(testName, block)
    if not block then
      error('No function provided')
    end

    runHooks(ut_hooks.before)
    runHooks(test_hooks.before)

    local expectation = createExpectation(false, nil, nil)
    local success, err = pcall(block, expectation.expect)

    runHooks(test_hooks.after)
    runHooks(ut_hooks.after)

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

---@param config {verbose?: boolean, ut_hooks?: InstanceHooks, describe_hooks?: InstanceHooks}
---@return fun(description: string, block: DescribeBlock): DescribeResult
local function createDescribeFunction(config)
  local verbose = config.verbose ~= false
  local hooks = config.describe_hooks or {
    before = {},
    after = {},
  }
  local ut_hooks = config.ut_hooks or {
    before = {},
    after = {},
  }

  return function(description, block)
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

    local local_test_hooks = {
      before = {},
      after = {}
    }

    local localTest = {}
    ---@type TestInstance
    localTest = setmetatable(localTest, {
      ---@type TestMetaCall
      __call = function(_, testName, block)
        local testFn = createTestFunction{
          onTest = function(_testName, result)
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
          end,
          -- The ut_hooks are passed to the base test instance,
          -- but not to the local test instance in the describe block.
          -- ut_hooks = ut_hooks,
          test_hooks = local_test_hooks
        }

        return testFn(testName, block)
      end
    })

    function localTest.beforeEach(hook)
      table.insert(local_test_hooks.before, hook)
    end

    function localTest.afterEach(hook)
      table.insert(local_test_hooks.after, hook)
    end

    runHooks(ut_hooks.before)
    runHooks(hooks.before)

    block(localTest)

    runHooks(hooks.after)
    runHooks(ut_hooks.after)

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
end

---@param config? {verbose?: boolean}
---@return UtInstance
local function create_instance(config)
  config = config or {}
  local verbose = config.verbose ~= false

  local hooks = {
    before = {},
    after = {}
  }

  local test = {}
  local test_hooks = {
    before = {},
    after = {}
  }

  ---@type TestInstance
  test = setmetatable(test, {
    ---@type TestMetaCall
    __call = function(_, testName, block)
      local testFn = createTestFunction{
        onTest = function(_testName, result)
          printResult{
            testName = _testName,
            failed = result.failed,
            verbose = verbose
          }
        end,
        ut_hooks = hooks,
        test_hooks = test_hooks
      }

      return testFn(testName, block)
    end
  })

  function test.beforeEach(hook)
    table.insert(test_hooks.before, hook)
  end

  function test.afterEach(hook)
    table.insert(test_hooks.after, hook)
  end

  local describe = {}
  local describe_hooks = {
    before = {},
    after = {}
  }

  ---@type DescribeInstance
  describe = setmetatable(describe, {
    ---@type DescribeMetaCall
    __call = function(_, description, block)
      local describeFn = createDescribeFunction{
        verbose = verbose,
        ut_hooks = hooks,
        describe_hooks = describe_hooks
      }
      return describeFn(description, block)
    end
  })

  function describe.beforeEach(hook)
    table.insert(describe_hooks.before, hook)
  end

  function describe.afterEach(hook)
    table.insert(describe_hooks.after, hook)
  end

  ---@type UtInstance
  local instance = {
    test = test,
    describe = describe,
    beforeEach = function(hook)
      table.insert(hooks.before, hook)
    end,
    afterEach = function(hook)
      table.insert(hooks.after, hook)
    end
  }

  return instance
end

return create_instance
