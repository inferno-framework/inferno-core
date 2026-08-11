import React from 'react';
import { screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { RunnableType } from '~/models/testSuiteModels';
import { renderWithProviders } from '~/test-utils';
import TestRunButton from '../TestRunButton';
import {
  mockedTestRunButtonData,
  mockedUnrunnableTestRunButtonData,
} from '../__mocked_data__/mockData';

describe('The TestRunButton Component', () => {
  it('does not render TestRunButton if test is not runnable', () => {
    renderWithProviders(
      <TestRunButton
        runnable={mockedUnrunnableTestRunButtonData.test}
        runnableType={RunnableType.Test}
        runTests={mockedUnrunnableTestRunButtonData.runTests}
      />,
    );

    const buttonElements = screen.queryAllByRole('button');
    expect(buttonElements).toHaveLength(0);
  });

  it('renders TestRunButton for tests', () => {
    renderWithProviders(
      <TestRunButton
        runnable={mockedTestRunButtonData.test}
        runnableType={RunnableType.Test}
        runTests={mockedTestRunButtonData.runTests}
      />,
    );

    const buttonElement = screen.queryByTestId(`runButton-${mockedTestRunButtonData.test.id}`);
    expect(buttonElement).toBeInTheDocument();
  });

  it('runs tests on icon button click', async () => {
    const runTests = vi.spyOn(mockedTestRunButtonData, 'runTests');
    const { user } = renderWithProviders(
      <TestRunButton
        runnable={mockedTestRunButtonData.test}
        runnableType={RunnableType.Test}
        runTests={mockedTestRunButtonData.runTests}
      />,
    );

    const buttonElement = screen.getByTestId(`runButton-${mockedTestRunButtonData.test.id}`);
    await user.click(buttonElement);
    expect(runTests).toBeCalledTimes(1);
  });

  it('runs tests on icon button Enter key', async () => {
    const runTests = vi.spyOn(mockedTestRunButtonData, 'runTests');
    const { user } = renderWithProviders(
      <TestRunButton
        runnable={mockedTestRunButtonData.test}
        runnableType={RunnableType.Test}
        runTests={mockedTestRunButtonData.runTests}
      />,
    );

    const buttonElement = screen.getByTestId(`runButton-${mockedTestRunButtonData.test.id}`);
    buttonElement.focus();
    await user.keyboard('{Enter}');
    expect(runTests).toBeCalledTimes(1);
  });

  it('runs tests on text button click when buttonText is provided', async () => {
    const runTests = vi.spyOn(mockedTestRunButtonData, 'runTests');
    const { user } = renderWithProviders(
      <TestRunButton
        runnable={mockedTestRunButtonData.test}
        runnableType={RunnableType.Test}
        runTests={mockedTestRunButtonData.runTests}
        buttonText="Run"
      />,
    );

    const buttonElement = screen.getByRole('button', { name: /run/i });
    await user.click(buttonElement);
    expect(runTests).toBeCalledTimes(1);
  });

  it('renders TestRunButton for test groups', () => {
    renderWithProviders(
      <TestRunButton
        runnable={mockedTestRunButtonData.testGroup}
        runnableType={RunnableType.TestGroup}
        runTests={mockedTestRunButtonData.runTests}
      />,
    );

    const buttonElement = screen.queryByTestId(`runButton-${mockedTestRunButtonData.testGroup.id}`);
    expect(buttonElement).toBeInTheDocument();
  });

  it('runs test group on button click', async () => {
    const runTests = vi.spyOn(mockedTestRunButtonData, 'runTests');
    const { user } = renderWithProviders(
      <TestRunButton
        runnable={mockedTestRunButtonData.testGroup}
        runnableType={RunnableType.TestGroup}
        runTests={mockedTestRunButtonData.runTests}
      />,
    );

    const buttonElement = screen.getByTestId(`runButton-${mockedTestRunButtonData.testGroup.id}`);
    await user.click(buttonElement);
    expect(runTests).toBeCalledTimes(1);
  });

  it('renders TestRunButton for test suites', () => {
    renderWithProviders(
      <TestRunButton
        runnable={mockedTestRunButtonData.testSuite}
        runnableType={RunnableType.TestSuite}
        runTests={mockedTestRunButtonData.runTests}
      />,
    );

    const buttonElement = screen.queryByTestId(`runButton-${mockedTestRunButtonData.testSuite.id}`);
    expect(buttonElement).toBeInTheDocument();
  });

  it('runs test suite on button click', async () => {
    const runTests = vi.spyOn(mockedTestRunButtonData, 'runTests');
    const { user } = renderWithProviders(
      <TestRunButton
        runnable={mockedTestRunButtonData.testSuite}
        runnableType={RunnableType.TestSuite}
        runTests={mockedTestRunButtonData.runTests}
      />,
    );

    const buttonElement = screen.getByTestId(`runButton-${mockedTestRunButtonData.testSuite.id}`);
    await user.click(buttonElement);
    expect(runTests).toBeCalledTimes(1);
  });
});
