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
        type: (props?.type || 'text') as TestInput['type'],
        title: props?.title,
        optional: props?.optional,
        show_if: props?.show_if,
        hidden: props?.hidden,
        value: props?.value,
      };
    };

    const constructInputsMap = (inputs: TestInput[]): Map<string, string> => {
      return inputs.reduce((acc, input) => {
        acc.set(input.name, input.value as string);
        return acc;
      }, new Map<string, string>());
    };

    const renderInputFields = (inputs: TestInput[], inputsMap: Map<string, string>) => {
      render(
        <ThemeProvider>
          <SnackbarProvider>
            <InputFields inputs={inputs} inputsMap={inputsMap} setInputsMap={() => {}} />
          </SnackbarProvider>
        </ThemeProvider>,
      );
    };

    const assertInputVisibility = (
      inputs: Partial<TestInput>[],
      expectedVisible: boolean[],
    ) => {
      const constructedInputs: TestInput[] = inputs.map((input) => constructInput(input));
      const inputsMap = constructInputsMap(constructedInputs);
      renderInputFields(constructedInputs, inputsMap);

      constructedInputs.forEach((input, index) => {
        const label = input.title as string;
        const shouldBeVisible = expectedVisible[index];
        if (shouldBeVisible) {
          expect(screen.getByLabelText(label, { exact: false })).toBeVisible();
        } else {
          expect(screen.queryByLabelText(label, { exact: false })).not.toBeInTheDocument();
        }
      });
    };

    it('renders field when it has no show_if (always visible)', () => {
      assertInputVisibility(
        [
          { name: 'standalone', title: 'Standalone field' },
        ],
        [true],
      );
    });

    it('skips rendering dependent field when controlling value is undefined', () => {
      assertInputVisibility(
        [
          { name: 'trigger', title: 'Trigger' },
          {
            name: 'dependent',
            title: 'Dependent',
            show_if: { input_name: 'trigger', value: 'yes' },
          },
        ],
        [true, false],
      );
    });

    it('skips rendering when controlling value does not match show_if', () => {
      assertInputVisibility(
        [
          { name: 'trigger', title: 'Trigger', value: 'no' },
          {
            name: 'dependent',
            title: 'Dependent',
            show_if: { input_name: 'trigger', value: 'yes' },
          },
        ],
        [true, false],
      );
    });

    it('renders dependent field when controlling value matches show_if', () => {
      assertInputVisibility(
        [
          { name: 'trigger', title: 'Trigger', value: 'yes' },
          {
            name: 'dependent',
            title: 'Dependent',
            show_if: { input_name: 'trigger', value: 'yes' },
          },
        ],
        [true, true],
      );
    });

    it('hides field when hidden is true even if show_if would pass', () => {
      assertInputVisibility(
        [
          { name: 'trigger', title: 'Trigger', value: 'yes' },
          {
            name: 'dependent',
            title: 'Dependent',
            show_if: { input_name: 'trigger', value: 'yes' },
            hidden: true,
          },
        ],
        [true, false],
      );
    });

    it('renders dependent field when controlling value (array) equals show_if array value', () => {
      // When ref value in map is an array, show_if.value as string[] matches via isEqual (same elements)
      const refValue = ['a', 'b'];
      const inputs: TestInput[] = [
        constructInput({
          name: 'trigger',
          title: 'Trigger',
          type: 'checkbox',
          value: refValue,
        }),
        constructInput({
          name: 'dependent',
          title: 'Dependent',
          show_if: { input_name: 'trigger', value: ['a', 'b'] },
        }),
      ];
      const inputsMap = new Map<string, unknown>();
      inputsMap.set('trigger', refValue);
      render(
        <ThemeProvider>
          <SnackbarProvider>
            <InputFields inputs={inputs} inputsMap={inputsMap} setInputsMap={() => {}} />
          </SnackbarProvider>
        </ThemeProvider>,
      );

      expect(screen.getByRole('checkbox', { name: /Trigger/i })).toBeInTheDocument();
      expect(screen.getByRole('textbox', { name: /Dependent/i })).toBeVisible();
    });
  })
});
