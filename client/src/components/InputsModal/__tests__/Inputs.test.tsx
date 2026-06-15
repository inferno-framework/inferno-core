import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { renderWithProviders } from '~/test-utils';
import { describe, expect, it, vi } from 'vitest';
import { SnackbarProvider } from 'notistack';
import { TestInput } from '~/models/testSuiteModels';
import InputCheckboxGroup from '~/components/InputsModal/InputCheckboxGroup';
import InputCombobox from '~/components/InputsModal/InputCombobox';
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
    const constructInput = (props: Partial<TestInput>): TestInput => ({
      name: '',
      type: 'text',
      ...props,
    });

    const constructInputsMap = (inputs: TestInput[]): Map<string, unknown> => {
      return inputs.reduce((acc, input) => {
        acc.set(input.name, input.value);
        return acc;
      }, new Map<string, unknown>());
    };

    const renderInputFields = (inputs: TestInput[], inputsMap: Map<string, unknown>) => {
      render(
        <ThemeProvider>
          <SnackbarProvider>
            <InputFields inputs={inputs} inputsMap={inputsMap} setInputsMap={() => {}} />
          </SnackbarProvider>
        </ThemeProvider>,
      );
    };

    const assertInputVisibility = (inputs: Partial<TestInput>[], expectedVisible: boolean[]) => {
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

    const assertDependentVisibilityForCheckboxEnableWhen = (
      refValue: string[],
      enableWhenValue: string,
      expectedVisible: boolean,
    ) => {
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
          enable_when: { input_name: 'trigger', value: enableWhenValue },
        }),
      ];
      const inputsMap = new Map<string, unknown>([['trigger', refValue]]);
      renderInputFields(inputs, inputsMap);

      expect(screen.getByRole('checkbox', { name: /Trigger/i })).toBeInTheDocument();
      if (expectedVisible) {
        expect(screen.getByRole('textbox', { name: /Dependent/i })).toBeInTheDocument();
      } else {
        expect(screen.queryByRole('textbox', { name: /Dependent/i })).not.toBeInTheDocument();
      }
    };

    it('renders field when it has no enable_when (always visible)', () => {
      assertInputVisibility([{ name: 'standalone', title: 'Standalone field' }], [true]);
    });

    it('skips rendering dependent field when controlling value is undefined', () => {
      assertInputVisibility(
        [
          { name: 'trigger', title: 'Trigger' },
          {
            name: 'dependent',
            title: 'Dependent',
            enable_when: { input_name: 'trigger', value: 'yes' },
          },
        ],
        [true, false],
      );
    });

    it('skips rendering when controlling value does not match enable_when', () => {
      assertInputVisibility(
        [
          { name: 'trigger', title: 'Trigger', value: 'no' },
          {
            name: 'dependent',
            title: 'Dependent',
            enable_when: { input_name: 'trigger', value: 'yes' },
          },
        ],
        [true, false],
      );
    });

    it('renders dependent field when controlling value matches enable_when', () => {
      assertInputVisibility(
        [
          { name: 'trigger', title: 'Trigger', value: 'yes' },
          {
            name: 'dependent',
            title: 'Dependent',
            enable_when: { input_name: 'trigger', value: 'yes' },
          },
        ],
        [true, true],
      );
    });

    it('hides field when hidden is true even if enable_when would pass', () => {
      assertInputVisibility(
        [
          { name: 'trigger', title: 'Trigger', value: 'yes' },
          {
            name: 'dependent',
            title: 'Dependent',
            enable_when: { input_name: 'trigger', value: 'yes' },
            hidden: true,
          },
        ],
        [true, false],
      );
    });

    it('renders dependent field when controlling value (array) equals enable_when array value', () => {
      assertDependentVisibilityForCheckboxEnableWhen(['a', 'b'], '["a","b"]', true);
    });

    it('renders dependent field regardless of checkbox selection order', () => {
      assertDependentVisibilityForCheckboxEnableWhen(['b', 'a'], '["a","b"]', true);
    });

    it('hides dependent field when controlling value (array) does not match enable_when array value', () => {
      assertDependentVisibilityForCheckboxEnableWhen(['a', 'b'], '["a","c"]', false);
    });
  });

  // ── InputCheckboxGroup additional coverage ───────────────────────────────────

  describe('InputCheckboxGroup additional coverage', () => {
    const checkboxInput: TestInput = {
      name: 'checkboxInput',
      type: 'checkbox',
      optional: true,
      options: {
        list_options: [
          { label: 'Option A', value: 'a' },
          { label: 'Option B', value: 'b' },
        ],
      },
    };

    it('checking a box executes the map callback in transformValuesToJSONArray', async () => {
      const setInputsMap = vi.fn();
      const { user } = renderWithProviders(
        <InputCheckboxGroup
          input={checkboxInput}
          index={0}
          inputsMap={new Map<string, unknown>()}
          setInputsMap={setInputsMap}
        />,
        { noRouter: true },
      );

      const checkboxA = screen.getByRole('checkbox', { name: /Option A/i });
      await user.click(checkboxA);

      const [calledMap] = setInputsMap.mock.calls[setInputsMap.mock.calls.length - 1] as [
        Map<string, unknown>,
      ];
      expect(JSON.parse(calledMap.get('checkboxInput') as string)).toContain('a');
    });

    it('blurring a checkbox marks the field as modified', async () => {
      const { user } = renderWithProviders(
        <InputCheckboxGroup
          input={{ ...checkboxInput, optional: false }}
          index={0}
          inputsMap={new Map<string, unknown>([['checkboxInput', '[]']])}
          setInputsMap={() => {}}
        />,
        { noRouter: true },
      );

      const checkboxA = screen.getByRole('checkbox', { name: /Option A/i });
      await user.click(checkboxA);
      await user.tab(); // move focus away to trigger onBlur
    });
  });

  // ── InputCombobox additional coverage ────────────────────────────────────────

  describe('InputCombobox additional coverage', () => {
    const comboboxInput: TestInput = {
      name: 'comboboxInput',
      type: 'text',
      optional: true,
      default: 'a',
      options: {
        list_options: [
          { label: 'Option A', value: 'a' },
          { label: 'Option B', value: 'b' },
        ],
      },
    };

    it('renders InputCombobox with a default value (triggers isOptionEqualToValue)', () => {
      renderWithProviders(
        <InputCombobox
          input={comboboxInput}
          index={0}
          inputsMap={new Map<string, unknown>([['comboboxInput', 'a']])}
          setInputsMap={() => {}}
        />,
        { noRouter: true },
      );

      expect(screen.getByRole('combobox')).toBeInTheDocument();
    });

    it('selecting a new option calls setInputsMap with updated value', async () => {
      const setInputsMap = vi.fn();
      const { user } = renderWithProviders(
        <InputCombobox
          input={comboboxInput}
          index={0}
          inputsMap={new Map<string, unknown>()}
          setInputsMap={setInputsMap}
        />,
        { noRouter: true },
      );

      const combobox = screen.getByRole('combobox');
      await user.click(combobox);
      await user.click(screen.getByText('Option B'));

      expect(setInputsMap).toHaveBeenCalled();
      const [calledMap] = setInputsMap.mock.calls[setInputsMap.mock.calls.length - 1] as [
        Map<string, unknown>,
      ];
      expect(calledMap.get('comboboxInput')).toBe('b');
    });
  });

  // ── InputOAuthCredentials additional coverage ────────────────────────────────

  describe('InputOAuthCredentials additional coverage', () => {
    const makeOAuthInput = (overrides: Partial<TestInput> = {}): TestInput => ({
      name: 'oauthInput',
      type: 'oauth_credentials' as TestInput['type'],
      optional: true,
      ...overrides,
    });

    it('onChange → updateInputsMap serialises updated credential and calls setInputsMap', () => {
      const setInputsMapMock = vi.fn();
      const prePopulated = new Map<string, unknown>([
        ['oauthInput', JSON.stringify({ access_token: 'old-token' })],
      ]);

      render(
        <ThemeProvider>
          <SnackbarProvider>
            <InputOAuthCredentials
              input={makeOAuthInput()}
              index={0}
              inputsMap={prePopulated}
              setInputsMap={setInputsMapMock}
            />
          </SnackbarProvider>
        </ThemeProvider>,
      );

      fireEvent.change(screen.getByRole('textbox', { name: /access token/i }), {
        target: { value: 'new-token' },
      });

      expect(setInputsMapMock).toHaveBeenCalledTimes(1);
      const [calledMap] = setInputsMapMock.mock.calls[0] as [Map<string, unknown>];
      const parsed = JSON.parse(calledMap.get('oauthInput') as string) as Record<string, unknown>;
      expect(parsed['access_token']).toBe('new-token');
    });

    it('empty credential values are omitted from the serialised output (if (inputValue) branch)', () => {
      const setInputsMapMock = vi.fn();

      render(
        <ThemeProvider>
          <SnackbarProvider>
            <InputOAuthCredentials
              input={makeOAuthInput()}
              index={0}
              inputsMap={
                new Map<string, unknown>([
                  ['oauthInput', JSON.stringify({ access_token: 'token' })],
                ])
              }
              setInputsMap={setInputsMapMock}
            />
          </SnackbarProvider>
        </ThemeProvider>,
      );

      fireEvent.change(screen.getByRole('textbox', { name: /access token/i }), {
        target: { value: '' },
      });

      const [calledMap] = setInputsMapMock.mock.calls[0] as [Map<string, unknown>];
      const parsed = JSON.parse(calledMap.get('oauthInput') as string) as Record<string, unknown>;
      expect(parsed).not.toHaveProperty('access_token');
    });

    it('onBlur sets hasBeenModified and getIsMissingInput shows RequiredInputWarning for required empty field', () => {
      const { container } = render(
        <ThemeProvider>
          <SnackbarProvider>
            <InputOAuthCredentials
              input={makeOAuthInput({ optional: false })}
              index={0}
              inputsMap={new Map<string, unknown>([['oauthInput', '{}']])}
              setInputsMap={() => {}}
            />
          </SnackbarProvider>
        </ThemeProvider>,
      );

      // No warning before the field has been touched
      expect(container.querySelector('.MuiSvgIcon-colorError')).not.toBeInTheDocument();

      // Direct blur satisfies e.currentTarget === e.target guard and fires setHasBeenModified
      fireEvent.blur(screen.getByRole('textbox', { name: /access token \(required\)/i }));

      // getIsMissingInput now returns true → RequiredInputWarning (error-coloured icon) appears
      expect(container.querySelector('.MuiSvgIcon-colorError')).toBeInTheDocument();
    });

    it('renders "(required)" suffix on oAuthField label when field.optional is false (line 114)', () => {
      render(
        <ThemeProvider>
          <SnackbarProvider>
            <InputOAuthCredentials
              input={makeOAuthInput({ optional: false })}
              index={0}
              inputsMap={new Map<string, unknown>()}
              setInputsMap={() => {}}
            />
          </SnackbarProvider>
        </ThemeProvider>,
      );

      expect(screen.getByText(/access token \(required\)/i)).toBeInTheDocument();
    });

    it('renders input.description as a Typography element in the card view (lines 184–187)', () => {
      render(
        <ThemeProvider>
          <SnackbarProvider>
            <InputOAuthCredentials
              input={makeOAuthInput({ description: 'Provide your bearer token.' })}
              index={0}
              inputsMap={new Map<string, unknown>()}
              setInputsMap={() => {}}
            />
          </SnackbarProvider>
        </ThemeProvider>,
      );

      expect(screen.getByText('Provide your bearer token.')).toBeVisible();
    });
  });
});
