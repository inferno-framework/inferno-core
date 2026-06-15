import React, { act } from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import InputsModal from '../InputsModal';
import { RunnableType, TestInput } from '~/models/testSuiteModels';
import ThemeProvider from 'components/ThemeProvider';
import { SnackbarProvider } from 'notistack';

import { beforeEach, expect, test, vi } from 'vitest';
import {
  mockedTestGroup,
  mockedTestSuite,
  mockedTest,
} from '~/components/_common/__mocked_data__/mockData';

const hideModalMock = vi.fn();
const createTestRunMock = vi.fn();

beforeEach(() => vi.clearAllMocks());

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
    default: ['value'],
  },
];

const mockedSessionData = testInputs.reduce((acc, input) => acc.set(input.name, ''), new Map());

test('Modal visible and inputs are shown', () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestGroup}
          runnableType={RunnableType.TestGroup}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  const titleText = screen.getByText('Mock Test Group');
  expect(titleText).toBeVisible();

  testInputs.forEach((input: TestInput) => {
    if (input.optional) {
      const inputField = screen.getByLabelText(input.name);
      expect(inputField).toBeVisible();
    } else {
      const inputField = screen.getByText(input.name + ' (required)');
      expect(inputField).toBeVisible();
    }
  });
});

test('Pressing cancel hides the modal', async () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestGroup}
          runnableType={RunnableType.TestGroup}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  const cancelButton = screen.getByTestId('cancel-button');
  await userEvent.click(cancelButton);
  expect(hideModalMock).toHaveBeenCalled();
});

test('Pressing submit hides the modal', async () => {
  await act(() =>
    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputsModal
            modalVisible={true}
            hideModal={hideModalMock}
            runnable={mockedTestGroup}
            runnableType={RunnableType.TestGroup}
            inputs={testInputs}
            sessionData={mockedSessionData}
            createTestRun={createTestRunMock}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    ),
  );

  const submitButton = screen.getByText('Submit');
  expect(submitButton).toBeDisabled();

  const inputs = screen.findAllByRole('textbox');
  (await inputs).forEach((input) => {
    fireEvent.change(input, { target: { value: 'filler text' } });
  });

  expect(submitButton).toBeEnabled();
  await userEvent.click(submitButton);
  expect(hideModalMock).toHaveBeenCalled();
});

test('Field Inputs shown in JSON and YAML', async () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestGroup}
          runnableType={RunnableType.TestGroup}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  const jsonButton = screen.getByTestId('json-button');
  const yamlButton = screen.getByTestId('yaml-button');

  await userEvent.click(jsonButton);
  let serial = screen.getByTestId('serial-input').textContent || '';

  testInputs.forEach((input: TestInput) => {
    expect(serial.includes(input.name));
  });

  await userEvent.click(yamlButton);
  serial = screen.getByTestId('serial-input').textContent || '';

  testInputs.forEach((input: TestInput) => {
    expect(serial.includes(input.name));
  });
});

test('Values in Field Inputs shown in JSON and YAML', async () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestGroup}
          runnableType={RunnableType.TestGroup}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  const jsonButton = screen.getByTestId('json-button');
  const yamlButton = screen.getByTestId('yaml-button');

  await userEvent.click(jsonButton);
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

  await userEvent.click(yamlButton);
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

// ── runnableTypeReadable switch ────────────────────────────────────────────────

test('instruction text uses "test suite" for RunnableType.TestSuite', () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestSuite}
          runnableType={RunnableType.TestSuite}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );
  expect(screen.getByText(/run the test suite/)).toBeInTheDocument();
});

test('instruction text uses "test" for RunnableType.Test', () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTest}
          runnableType={RunnableType.Test}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );
  // regex anchors to the literal period so it won't match "test suite" or "test group"
  expect(screen.getByText(/run the test\./)).toBeInTheDocument();
});

// ── serial input (handleSerialChanges + parsedChanges.forEach) ─────────────────

test('typing valid JSON in the serial input exercises handleSerialChanges', async () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestGroup}
          runnableType={RunnableType.TestGroup}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  await userEvent.click(screen.getByTestId('json-button'));

  const validJson = JSON.stringify([
    { name: 'url', value: 'http://example.com' },
    { name: 'some other input', value: 'opt' },
    { name: 'yet another input', value: 'req' },
  ]);
  const serialTextarea = screen.getByRole('textbox', { name: 'JSON' });
  fireEvent.change(serialTextarea, { target: { value: validJson } });

  expect(serialTextarea).toHaveValue(validJson);
});

// ── file upload (handleFileUpload) ─────────────────────────────────────────────

test('file upload populates the serial input via handleFileUpload', async () => {
  const fileContent = JSON.stringify([{ name: 'url', value: 'http://uploaded.example.com' }]);

  class MockFileReader {
    result = fileContent;
    onload: (() => void) | null = null;
    readAsText() {
      this.onload?.();
    }
  }
  vi.stubGlobal('FileReader', MockFileReader);

  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestGroup}
          runnableType={RunnableType.TestGroup}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  await userEvent.click(screen.getByTestId('json-button'));

  const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement;
  const file = new File([fileContent], 'inputs.json', { type: 'application/json' });
  fireEvent.change(fileInput, { target: { files: [file] } });

  expect(screen.getByRole('textbox', { name: 'JSON' })).toHaveValue(fileContent);

  vi.unstubAllGlobals();
});

// ── cancel / close interactions ────────────────────────────────────────────────

test('X cancel IconButton calls hideModal', async () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestGroup}
          runnableType={RunnableType.TestGroup}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  // aria-label="cancel" uniquely identifies the X IconButton (Cancel button text is capitalised)
  await userEvent.click(screen.getByRole('button', { name: 'cancel' }));
  expect(hideModalMock).toHaveBeenCalled();
});

test('closing the dialog via onClose calls hideModal when inputs are unedited', async () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestGroup}
          runnableType={RunnableType.TestGroup}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  await userEvent.keyboard('{Escape}');
  expect(hideModalMock).toHaveBeenCalled();
});

test('closing the dialog via onClose does not call hideModal after inputs are edited', async () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <InputsModal
          modalVisible={true}
          hideModal={hideModalMock}
          runnable={mockedTestGroup}
          runnableType={RunnableType.TestGroup}
          inputs={testInputs}
          sessionData={mockedSessionData}
          createTestRun={createTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  // Editing a field sets inputsEdited=true; InputTextField calls setInputsMap without edited=false
  // so handleSetInputsMap treats it as edited (edited !== false → true)
  const textboxes = screen.getAllByRole('textbox');
  fireEvent.change(textboxes[0], { target: { value: 'edited value' } });

  await userEvent.keyboard('{Escape}');
  expect(hideModalMock).not.toHaveBeenCalled();
});

// ── keyboard submit (handleSubmitKeydown) ──────────────────────────────────────

test('Cmd+Enter submits the form when all required inputs are filled', async () => {
  const filledSessionData = new Map([
    ['url', 'http://example.com'],
    ['some other input', 'optional value'],
    ['yet another input', 'required value'],
  ]);

  await act(() =>
    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputsModal
            modalVisible={true}
            hideModal={hideModalMock}
            runnable={mockedTestGroup}
            runnableType={RunnableType.TestGroup}
            inputs={testInputs}
            sessionData={filledSessionData}
            createTestRun={createTestRunMock}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    ),
  );

  fireEvent.keyDown(screen.getByRole('dialog'), { key: 'Enter', metaKey: true });
  expect(createTestRunMock).toHaveBeenCalled();
});
