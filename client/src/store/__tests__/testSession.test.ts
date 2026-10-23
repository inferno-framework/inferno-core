import { renderHook, act } from '@testing-library/react';
import { expect, test, beforeEach } from 'vitest';
import { useTestSessionStore } from '../testSession';

beforeEach(() => {
  const { result } = renderHook(() => useTestSessionStore((state) => state));
  act(() => {
    result.current.setRunnableId('');
  });
});

test('setRunnableId stores the given runnable id', () => {
  const { result } = renderHook(() => useTestSessionStore((state) => state));

  act(() => {
    result.current.setRunnableId('group-1');
  });

  expect(result.current.runnableId).toEqual('group-1');
});
