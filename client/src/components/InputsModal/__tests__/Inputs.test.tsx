import React from 'react';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import { TestInput } from '~/models/testSuiteModels';
import ThemeProvider from '~/components/ThemeProvider';
import InputCheckboxGroup from '~/components/InputsModal/InputCheckboxGroup';
import InputRadioGroup from '~/components/InputsModal/InputRadioGroup';
import InputTextField from '~/components/InputsModal/InputTextField';
import InputOAuthCredentials from '~/components/InputsModal/InputOAuthCredentials';
import InputAuth from '~/components/InputsModal/Auth/InputAuth';
import InputAccess from '~/components/InputsModal/Auth/InputAccess';
import { describe, expect, it } from 'vitest';

describe('Input Components', () => {
  it('renders InputCheckboxGroup', () => {
    const checkboxInput = {
      name: 'checkboxInput',
      type: 'checkbox' as TestInput['type'],
      optional: true,
      options: {
        list_options: [
          {
            label: 'option1',
            value: '1',
          },
          {
            label: 'option2',
            value: '2',
          },
        ],
      },
    };

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputCheckboxGroup
            input={checkboxInput}
            index={0}
            inputsMap={new Map<string, string>()}
            setInputsMap={() => {}}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const inputText = screen.getByText('checkboxInput');
    expect(inputText).toBeVisible();
  });

  it('renders InputRadioGroup', () => {
    const radioInput = {
      name: 'radioInput',
      type: 'radio' as TestInput['type'],
      optional: true,
      options: {
        list_options: [
          {
            label: 'option1',
            value: '1',
          },
          {
            label: 'option2',
            value: '2',
          },
        ],
      },
    };

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputRadioGroup
            input={radioInput}
            index={0}
            inputsMap={new Map<string, string>()}
            setInputsMap={() => {}}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const inputText = screen.getByText('radioInput');
    expect(inputText).toBeVisible();
  });

  it('renders InputTextField (single line)', () => {
    const textInput = {
      name: 'textInput',
      type: 'text' as TestInput['type'],
      optional: true,
    };

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputTextField
            input={textInput}
            index={0}
            inputsMap={new Map<string, string>()}
            setInputsMap={() => {}}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const inputText = screen.getByText('textInput');
    expect(inputText).toBeVisible();
  });

  it('renders InputTextField (multiline)', () => {
    const textareaInput = {
      name: 'textareaInput',
      type: 'textarea' as TestInput['type'],
      optional: true,
    };

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputTextField
            input={textareaInput}
            index={0}
            inputsMap={new Map<string, string>()}
            setInputsMap={() => {}}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const inputText = screen.getByText('textareaInput');
    expect(inputText).toBeVisible();
  });

  it('renders InputOAuthCredentials', () => {
    const oauthInput = {
      name: 'oauthInput',
      type: 'oauth' as TestInput['type'],
      optional: true,
    };

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputOAuthCredentials
            input={oauthInput}
            index={0}
            inputsMap={new Map<string, string>()}
            setInputsMap={() => {}}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const inputText = screen.getByText('oauthInput');
    expect(inputText).toBeVisible();
  });

  it('renders InputAuth', () => {
    const authInput = {
      name: 'authInput',
      type: 'auth_info' as TestInput['type'],
      optional: true,
      options: {
        mode: 'auth',
        components: [
          {
            default: 'public',
            name: 'auth_type',
          },
        ],
      },
    };

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputAuth
            input={authInput}
            index={0}
            inputsMap={new Map<string, string>()}
            setInputsMap={() => {}}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const inputText = screen.getByText('Auth Type (required)');
    expect(inputText).toBeVisible();
  });

  it('renders InputAccess', () => {
    const accessInput = {
      name: 'accessInput',
      type: 'auth_info' as TestInput['type'],
      optional: true,
      options: {
        mode: 'access',
        components: [
          {
            default: 'public',
            name: 'auth_type',
          },
        ],
      },
    };

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputAccess
            input={accessInput}
            index={0}
            inputsMap={new Map<string, string>()}
            setInputsMap={() => {}}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const inputText = screen.getByText('accessInput');
    expect(inputText).toBeVisible();
  });
});
