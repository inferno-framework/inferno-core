import { renderHook, act } from '@testing-library/react';
import { expect, test, beforeEach } from 'vitest';
import { useAppStore } from '../app';
import { TestSession } from '~/models/testSuiteModels';

const mockTestSession: TestSession = {
  id: 'session-1',
  test_suite_id: 'suite-1',
  test_suite: {
    id: 'suite-1',
    title: 'Mock Suite',
    inputs: [],
    test_groups: [],
  },
};

beforeEach(() => {
  const { result } = renderHook(() => useAppStore((state) => state));
  act(() => {
    result.current.setTestSession(undefined);
  });
});

test('setTestSession stores the given session', () => {
  const { result } = renderHook(() => useAppStore((state) => state));

  act(() => {
    result.current.setTestSession(mockTestSession);
  });

  expect(result.current.testSession).toEqual(mockTestSession);
});

test('setTestSession can clear the session with undefined', () => {
  const { result } = renderHook(() => useAppStore((state) => state));

  act(() => {
    result.current.setTestSession(mockTestSession);
  });
  act(() => {
    result.current.setTestSession(undefined);
  });

  expect(result.current.testSession).toBeUndefined();
});
