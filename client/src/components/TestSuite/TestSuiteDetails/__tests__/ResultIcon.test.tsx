import React from 'react';
import { renderWithProviders, screen, fireEvent } from '~/test-utils';
import { describe, expect, it } from 'vitest';
import ResultIcon from '../ResultIcon';
import { Result } from '~/models/testSuiteModels';

function makeResult(overrides: Partial<Result> = {}): Result {
  return {
    id: 'test-result',
    result: 'pass',
    test_run_id: 'run-1',
    test_session_id: 'session-1',
    updated_at: '2024-01-01',
    outputs: [],
    ...overrides,
  };
}

// The store's testRunId defaults to undefined, so any result.test_run_id !== undefined → pending.
describe('ResultIcon', () => {
  it('shows the pass icon for a pass result', () => {
    renderWithProviders(<ResultIcon result={makeResult({ result: 'pass' })} />);
    expect(screen.getByTestId('test-result-pass')).toBeInTheDocument();
  });

  it('shows the fail icon for a fail result', () => {
    renderWithProviders(<ResultIcon result={makeResult({ result: 'fail' })} />);
    expect(screen.getByTestId('test-result-fail')).toBeInTheDocument();
  });

  it('shows the cancel icon for a cancel result', () => {
    renderWithProviders(<ResultIcon result={makeResult({ result: 'cancel' })} />);
    expect(screen.getByTestId('test-result-cancel')).toBeInTheDocument();
  });

  it('shows the skip icon for a skip result', () => {
    renderWithProviders(<ResultIcon result={makeResult({ result: 'skip' })} />);
    expect(screen.getByTestId('test-result-skip')).toBeInTheDocument();
  });

  it('shows the omit icon for an omit result', () => {
    renderWithProviders(<ResultIcon result={makeResult({ result: 'omit' })} />);
    expect(screen.getByTestId('test-result-omit')).toBeInTheDocument();
  });

  it('shows the error icon for an error result', () => {
    renderWithProviders(<ResultIcon result={makeResult({ result: 'error' })} />);
    expect(screen.getByTestId('test-result-error')).toBeInTheDocument();
  });

  it('shows the wait icon for a wait result', () => {
    renderWithProviders(<ResultIcon result={makeResult({ result: 'wait' })} />);
    expect(screen.getByTestId('test-result-wait')).toBeInTheDocument();
  });

  it('shows a pending tooltip when isRunning with a non-current run id', async () => {
    const { container } = renderWithProviders(
      <ResultIcon result={makeResult({ test_run_id: 'run-1' })} isRunning={true} />,
    );
    fireEvent.mouseOver(container.querySelector('svg')!);
    expect(await screen.findByText('pending')).toBeInTheDocument();
  });

  it('shows a no-result tooltip when result is undefined', async () => {
    const { container } = renderWithProviders(<ResultIcon />);
    fireEvent.mouseOver(container.querySelector('svg')!);
    expect(await screen.findByText('no result')).toBeInTheDocument();
  });

  it('shows a no-result tooltip for an unrecognized result value', async () => {
    const { container } = renderWithProviders(
      <ResultIcon result={makeResult({ result: 'unknown-state' })} />,
    );
    fireEvent.mouseOver(container.querySelector('svg')!);
    expect(await screen.findByText('no result')).toBeInTheDocument();
  });

  it('renders optional pass without error', () => {
    renderWithProviders(<ResultIcon result={makeResult({ result: 'pass', optional: true })} />);
    expect(screen.getByTestId('test-result-pass')).toBeInTheDocument();
  });

  it('renders optional fail without error', () => {
    renderWithProviders(<ResultIcon result={makeResult({ result: 'fail', optional: true })} />);
    expect(screen.getByTestId('test-result-fail')).toBeInTheDocument();
  });
});
