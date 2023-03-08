import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import InputsModal from '../InputsModal';
import { RunnableType, TestInput } from '~/models/testSuiteModels';
import ThemeProvider from 'components/ThemeProvider';

import { vi } from 'vitest';

const hideModalMock = vi.fn();
const createTestRunMock = vi.fn();

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
    default: { value: true },
  },
];

test('Input modal not visible if visibility set to false', () => {
  render(
    <ThemeProvider>
      <InputsModal
        hideModal={hideModalMock}
        title="Modal Title"
        createTestRun={createTestRunMock}
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
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputs}
        sessionData={new Map()}
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
        runnableType={RunnableType.TestGroup}
        runnableId={'test group id'}
        inputs={testInputsDefaults}
        sessionData={new Map()}
      />
    </ThemeProvider>
  );

  const jsonButton = screen.getByTestId('json-button');
  const yamlButton = screen.getByTestId('yaml-button');

  userEvent.click(jsonButton);
  let serial = screen.getByTestId('serial-input').textContent || '';

  testInputsDefaults.forEach((input: TestInput) => {
    if (input.default) {
      if (typeof input.default === 'string') expect(serial.includes(input.default));
      if (typeof input.default === 'object') {
        Object.keys(input.default).forEach((key) => expect(serial.includes(key)));
        Object.values(input.default).forEach((value) => expect(serial.includes(value.toString())));
      }
    }
  });

  userEvent.click(yamlButton);
  serial = screen.getByTestId('serial-input').textContent || '';

  testInputs.forEach((input: TestInput) => {
    if (input.default) {
      if (typeof input.default === 'string') expect(serial.includes(input.default));
      if (typeof input.default === 'object') {
        Object.keys(input.default).forEach((key) => expect(serial.includes(key)));
        Object.values(input.default).forEach((value) => expect(serial.includes(value.toString())));
      }
    }
  });
});
