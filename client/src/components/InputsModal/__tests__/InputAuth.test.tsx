import React from 'react';
import { SnackbarProvider } from 'notistack';
import { render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it } from 'vitest';
import { Auth, TestInput } from '~/models/testSuiteModels';
import ThemeProvider from '~/components/ThemeProvider';
import InputAuth from '~/components/InputsModal/Auth/InputAuth';
import { getAuthFields } from '~/components/InputsModal/Auth/AuthSettings';
import {
  mockedAccessInput,
  mockedAuthInput,
  mockedRequiredFilledAuthInput,
  mockedFullyFilledAuthInput,
} from '~/components/_common/__mocked_data__/mockData';
import userEvent from '@testing-library/user-event';

describe('InputAuth Component', () => {
  let inputsMap: Map<string, unknown> = new Map();
  const setInputsMap = (newValue: Map<string, unknown>) => {
    inputsMap = newValue;
  };

  beforeEach(() => {
    inputsMap = new Map();
  });

  it('renders InputAuth with provided default type', () => {
    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputAuth
            mode="auth"
            input={mockedAuthInput}
            index={0}
            inputsMap={inputsMap}
            setInputsMap={setInputsMap}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const inputText = screen.getByText('mock_auth_input');
    expect(inputText).toBeVisible();

    const authTypeSelector = screen.getByRole('combobox');
    expect(authTypeSelector).toHaveValue('Backend Services');
  });

  it('renders InputAccess with first option default type', () => {
    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputAuth
            mode="access"
            input={mockedAccessInput}
            index={0}
            inputsMap={inputsMap}
            setInputsMap={setInputsMap}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const inputText = screen.getByText('mock_access_input');
    expect(inputText).toBeVisible();

    const authTypeSelector = screen.getByRole('combobox');
    expect(authTypeSelector).toHaveValue('Public');
  });

  it('shows all unhidden auth inputs', async () => {
    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputAuth
            mode="auth"
            input={mockedFullyFilledAuthInput}
            index={0}
            inputsMap={inputsMap}
            setInputsMap={setInputsMap}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const authValuesJson: object = JSON.parse(inputsMap.get('mock_auth_input') as string);
    const authValuesMap = new Map(Object.entries(authValuesJson));
    const authInputFields: TestInput[] = getAuthFields(
      'backend_services',
      authValuesMap,
      mockedFullyFilledAuthInput.options?.components || [],
      false,
    );

    authInputFields.forEach((field) => {
      const { title } = field;
      if (title && typeof title === 'string') {
        let inputField;
        // radio and single checkbox have unique formatting
        if (field.type === 'radio' || (field.type === 'checkbox' && !field.options)) {
          inputField = screen.queryByText(title);
        } else if (field.optional) {
          inputField = screen.queryByLabelText(title);
        } else {
          inputField = screen.queryByText(title + ' (required)');
        }

        // Hidden fields should not render
        if (field.hide) {
          expect(inputField).toEqual(null);
        } else {
          expect(inputField).toBeVisible();
        }
      }
    });

    // Check that Token URL appears if Populate from discovery is unchecked (hidden should appear)
    const checkbox = screen.getByRole('checkbox');
    await userEvent.click(checkbox);
    const tokenUrlInput = screen.getByLabelText('Token URL');
    expect(tokenUrlInput).toBeInTheDocument();
  });

  // auth info empty strings are deleted
  it('deletes empty fields before submission', () => {
    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputAuth
            mode="auth"
            input={mockedRequiredFilledAuthInput}
            index={0}
            inputsMap={inputsMap}
            setInputsMap={setInputsMap}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const authValuesJson: object = JSON.parse(inputsMap.get('mock_auth_input') as string);
    const authValuesMap = new Map(Object.entries(authValuesJson));
    const authInputFields: TestInput[] = getAuthFields(
      'backend_services',
      authValuesMap,
      mockedFullyFilledAuthInput.options?.components || [],
      false,
    );

    const parsedAuthInput: Auth = JSON.parse(inputsMap.get('mock_auth_input') as string);
    authInputFields.forEach((field) => {
      const value = parsedAuthInput[field.name as keyof Auth];
      // Optional fields with no default value that are not radio buttons or single checkboxes
      // should be empty in mock data
      if (
        field.optional &&
        !field.default &&
        field.type !== 'radio' &&
        !(field.type === 'checkbox' && !field.options)
      ) {
        expect(value).toBe(undefined);
      } else {
        expect(value).not.toBe(undefined);
      }
    });
  });
});
