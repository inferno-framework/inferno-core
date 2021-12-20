import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import InputsModal from '../InputsModal';
import { RunnableType, TestInput } from 'models/testSuiteModels';
import ThemeProvider from 'components/ThemeProvider';

const hideModalMock = jest.fn();
const createTestRunMock = jest.fn();

const testInputs: TestInput[] = [
  {
    name: 'url',
  },
  {
    name: 'some other input',
    optional: true,
  },
  {
    name: 'yet another input',
  },
];

test('Input modal not visible if visibility set to false', () => {
  render(
    <ThemeProvider>
      <InputsModal
        hideModal={hideModalMock}
        createTestRun={createTestRunMock}
        modalVisible={false}
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputs}
      />
    </ThemeProvider>
  );
  const titleText = screen.queryByText('Test Inputs');
  expect(titleText).toBeNull();
});

test('Modal visible and inputs are shown', () => {
  render(
    <ThemeProvider>
      <InputsModal
        hideModal={hideModalMock}
        createTestRun={createTestRunMock}
        modalVisible={true}
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputs}
      />
    </ThemeProvider>
  );

  const titleText = screen.getByText('Test Inputs');
  expect(titleText).toBeVisible();

  testInputs.forEach((input: TestInput) => {
    if (input.optional) {
      const inputField = screen.getByLabelText(input.name);
      expect(inputField).toBeVisible();
    } else {
      const inputField = screen.getByLabelText(input.name + ' (required) *');
      expect(inputField).toBeVisible();
    }
  });
});

test('Pressing cancel hides the modal', () => {
  render(
    <ThemeProvider>
      <InputsModal
        hideModal={hideModalMock}
        createTestRun={createTestRunMock}
        modalVisible={true}
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputs}
      />
    </ThemeProvider>
  );

  const cancelButton = screen.getByTestId('cancel-button');
  userEvent.click(cancelButton);
  expect(hideModalMock).toHaveBeenCalled();
});
