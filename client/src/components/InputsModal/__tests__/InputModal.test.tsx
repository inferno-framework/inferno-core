import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import InputsModal from '../InputsModal';
import { RunnableType, TestInput } from 'models/testSuiteModels';
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
    <InputsModal
      hideModal={hideModalMock}
      createTestRun={createTestRunMock}
      modalVisible={false}
      runnableType={RunnableType.TestGroup}
      runnableId={'test group id'}
      inputs={testInputs}
    />
  );
  const titleText = screen.queryByText('Test Inputs');
  expect(titleText).toBeNull();
});

test('Modal visible and inputs are shown', () => {
  render(
    <InputsModal
      hideModal={hideModalMock}
      createTestRun={createTestRunMock}
      modalVisible={true}
      runnableType={RunnableType.TestGroup}
      runnableId={'test group id'}
      inputs={testInputs}
    />
  );
  const titleText = screen.getByText('Test Inputs');
  expect(titleText).toBeVisible();
  testInputs.forEach((input: TestInput) => {
    if (input.optional) {
      const inputField = screen.getByLabelText(input.name);
      expect(inputField).toBeVisible();
    } else {
      const inputField = screen.getByLabelText(input.name + ' (required)');
      expect(inputField).toBeVisible();
    }
  });
});

test('Pressing cancel hides the modal', () => {
  render(
    <InputsModal
      hideModal={hideModalMock}
      createTestRun={createTestRunMock}
      modalVisible={true}
      runnableType={RunnableType.TestGroup}
      runnableId={'test group id'}
      inputs={testInputs}
    />
  );

  const cancelButton = screen.getByTestId('cancel-button');
  fireEvent.click(cancelButton);
  expect(hideModalMock).toHaveBeenCalled();
});
