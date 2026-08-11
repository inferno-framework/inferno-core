import { describe, expect, it } from 'vitest';
import { setIsRunning, testRunInProgress } from '~/components/TestSuite/TestSuiteUtilities';
import { Test, TestGroup, TestSuite } from '~/models/testSuiteModels';

function makeTest(id: string): Test {
  return { id, title: id, short_id: id, inputs: [], outputs: [] };
}

function makeGroup(id: string, tests: Test[] = [], subGroups: TestGroup[] = []): TestGroup {
  return { id, title: id, short_id: id, inputs: [], outputs: [], tests, test_groups: subGroups };
}

describe('setIsRunning', () => {
  it('sets is_running on a flat TestGroup and all its tests', () => {
    const test = makeTest('t1');
    const group = makeGroup('g1', [test]);

    setIsRunning(group, true);

    expect(group.is_running).toBe(true);
    expect(test.is_running).toBe(true);
  });

  it('recurses into nested test groups', () => {
    const innerTest = makeTest('t-inner');
    const inner = makeGroup('g-inner', [innerTest]);
    const outer = makeGroup('g-outer', [], [inner]);

    setIsRunning(outer, true);

    expect(outer.is_running).toBe(true);
    expect(inner.is_running).toBe(true);
    expect(innerTest.is_running).toBe(true);
  });

  it('sets is_running to false on all nodes', () => {
    const test = makeTest('t1');
    const group = makeGroup('g1', [test]);
    group.is_running = true;
    test.is_running = true;

    setIsRunning(group, false);

    expect(group.is_running).toBe(false);
    expect(test.is_running).toBe(false);
  });

  it('sets is_running on a TestSuite and recurses into its groups', () => {
    const test = makeTest('t1');
    const group = makeGroup('g1', [test]);
    const suite: TestSuite = {
      id: 'suite-1',
      title: 'Suite',
      inputs: [],
      test_groups: [group],
    };

    setIsRunning(suite, true);

    expect(suite.is_running).toBe(true);
    expect(group.is_running).toBe(true);
    expect(test.is_running).toBe(true);
  });

  it('does nothing when runnable is falsy', () => {
    expect(() => setIsRunning(null as never, true)).not.toThrow();
  });
});

describe('testRunInProgress', () => {
  it('returns true when the session id from the URL is in activeRunnables', () => {
    const activeRunnables = { 'session-123': 'running' };
    expect(testRunInProgress(activeRunnables, '/suite/session-123')).toBe(true);
  });

  it('returns false when the session id is not in activeRunnables', () => {
    const activeRunnables = { 'session-999': 'running' };
    expect(testRunInProgress(activeRunnables, '/suite/session-123')).toBe(false);
  });

  it('strips query string before extracting session id', () => {
    const activeRunnables = { 'session-123': 'running' };
    expect(testRunInProgress(activeRunnables, '/suite/session-123?foo=bar')).toBe(true);
  });

  it('strips hash before extracting session id', () => {
    const activeRunnables = { 'session-123': 'running' };
    expect(testRunInProgress(activeRunnables, '/suite/session-123#demo')).toBe(true);
  });

  it('returns false for an empty activeRunnables object', () => {
    expect(testRunInProgress({}, '/suite/session-123')).toBe(false);
  });
});
