import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { SnackbarProvider } from 'notistack';
import { TestInput } from '~/models/testSuiteModels';
import InputCheckboxGroup from '~/components/InputsModal/InputCheckboxGroup';
import InputOAuthCredentials from '~/components/InputsModal/InputOAuthCredentials';
import InputRadioGroup from '~/components/InputsModal/InputRadioGroup';
import InputTextField from '~/components/InputsModal/InputTextField';
import { isJsonString } from '~/components/InputsModal/InputHelpers';
import ThemeProvider from '~/components/ThemeProvider';
import InputFields from '../InputFields';

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

  it('parses JSON correctly using isJsonString', () => {
    const failStrings = [
      '',
      'undefined',
      'null',
      '0',
      '1,2',
      'string',
      'false',
      true,
      0,
      undefined,
      null,
    ];

    const passStrings = ['{}', '{"test": "string"}'];

    failStrings.forEach((string) => {
      expect(isJsonString(string)).toEqual(false);
    });

    passStrings.forEach((string) => {
      expect(isJsonString(string)).toEqual(true);
    });
  });

  describe('renders conditional fields correctly', () => {
    const constructInput = (props: Partial<TestInput>): TestInput => {
      return {
        name: props?.name || '',
        type: props?.type || 'text' as TestInput['type'],
        title: props?.title,
        optional: props?.optional,
        show_if: props?.show_if,
        value: props?.value,
      }
    }
    const contructInputMap = (inputs: TestInput[]): Map<string, string> => {
      return inputs.reduce((acc, input) => {
        acc.set(input.name, input.value as string);
        return acc;
      }, new Map<string, string>());
    }
    const renderInputFields = (inputs: TestInput[], inputsMap: Map<string, string>) => {
      render(
        <ThemeProvider>
          <SnackbarProvider>
            <InputFields inputs={inputs} inputsMap={inputsMap} setInputsMap={() => {}} />
          </SnackbarProvider>
        </ThemeProvider>,
      );
    }
    const assertInputRendersCorrect = (inputs: Partial<TestInput>[], expected: boolean[]) => {
      const constructedInputs: TestInput[] = inputs.map((input) => constructInput(input));
      const inputsMap = contructInputMap(constructedInputs);
      renderInputFields(constructedInputs, inputsMap);

      constructedInputs.forEach((input, index) => {
        const targetInput = screen.queryByLabelText(input.title as string, { exact: false });
        if (expected[index]) {
          expect(targetInput).toBeInTheDocument();
        } else {
          expect(targetInput).not.toBeInTheDocument();
        }
      });
    }
    it('should skip render of the field if target value is undefined', () => {
      const name1 = (crypto.randomUUID());
      const name2 = (crypto.randomUUID());
      const title1 = (crypto.randomUUID());
      const title2 = (crypto.randomUUID());
      const value1 = (crypto.randomUUID());
      assertInputRendersCorrect([
        { name: name1, title: title1 },
        { name: name2, title: title2, show_if: { input_name: name1, value: value1 } },
      ], [true, false]);
    });
    it('Skip render if target value is not equal to existing one', () => {
      const name1 = (crypto.randomUUID());
      const name2 = (crypto.randomUUID());
      const title1 = (crypto.randomUUID());
      const title2 = (crypto.randomUUID());
      const value1 = (crypto.randomUUID());
      const value2 = (crypto.randomUUID());
      assertInputRendersCorrect([
        { name: name1, title: title1, value: value1 },
        { name: name2, title: title2, show_if: { input_name: name1, value: value2 } },
      ], [true, false]);
    })

    it('Render the field if target value is equal to existing one', () => {
      const name1 = (crypto.randomUUID());
      const name2 = (crypto.randomUUID());
      const title1 = (crypto.randomUUID());
      const title2 = (crypto.randomUUID());
      const value1 = (crypto.randomUUID());
      assertInputRendersCorrect([
        { name: name1, title: title1, value: value1 },
        { name: name2, title: title2, show_if: { input_name: name1, value: value1 } },
      ], [true, true]);
    })
  })
});
