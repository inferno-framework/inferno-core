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

const testInputsDefaults: TestInput[] = [
  {
    name: 'url',
    default: 'some_url',
  },
  {
    name: 'some other input',
    optional: true,
  },
  {
    name: 'yet another input',
    default: 'yet another value',
  },
];

test('Input modal not visible if visibility set to false', () => {
  render(
    <ThemeProvider>
      <InputsModal
        hideModal={hideModalMock}
        title="Modal Title"
        createTestRun={createTestRunMock}
        modalVisible={false}
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputs}
        sessionData={new Map()}
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
        title="Modal Title"
        createTestRun={createTestRunMock}
        modalVisible={true}
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputs}
        sessionData={new Map()}
      />
    </ThemeProvider>
  );

  const titleText = screen.getByText('Modal Title');
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
        title="Modal Title"
        createTestRun={createTestRunMock}
        modalVisible={true}
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputs}
        sessionData={new Map()}
      />
    </ThemeProvider>
  );

  const cancelButton = screen.getByTestId('cancel-button');
  userEvent.click(cancelButton);
  expect(hideModalMock).toHaveBeenCalled();
});

test('Field Inputs shown in JSON and YAML', () => {
  render(
    <ThemeProvider>
      <InputsModal
        hideModal={hideModalMock}
        title="Modal Title"
        createTestRun={createTestRunMock}
        modalVisible={true}
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputs}
      />
    </ThemeProvider>
  );

  const jsonButton = screen.getByTestId('json-button');
  const yamlButton = screen.getByTestId('yaml-button');

  userEvent.click(jsonButton);
  let serial = screen.getByTestId('serial-input').textContent || '';

  testInputs.forEach((input: TestInput) => {
    expect(serial.includes(input.name));
  });

  userEvent.click(yamlButton);
  serial = screen.getByTestId('serial-input').textContent || '';

  testInputs.forEach((input: TestInput) => {
    expect(serial.includes(input.name));
  });
});

test('Values in Field Inputs shown in JSON and YAML', () => {
  render(
    <ThemeProvider>
      <InputsModal
        hideModal={hideModalMock}
        title="Modal Title"
        createTestRun={createTestRunMock}
        modalVisible={true}
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputsDefaults}
      />
    </ThemeProvider>
  );

  const jsonButton = screen.getByTestId('json-button');
  const yamlButton = screen.getByTestId('yaml-button');

  userEvent.click(jsonButton);
  let serial = screen.getByTestId('serial-input').textContent || '';

  testInputsDefaults.forEach((input: TestInput) => {
    if (input.default) expect(serial.includes(input.default));
  });

  userEvent.click(yamlButton);
  serial = screen.getByTestId('serial-input').textContent || '';

  testInputs.forEach((input: TestInput) => {
    if (input.default) expect(serial.includes(input.default));
  });
});
