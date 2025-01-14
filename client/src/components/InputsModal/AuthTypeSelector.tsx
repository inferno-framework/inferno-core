import React, { FC } from 'react';
import { InputOption, TestInput } from '~/models/testSuiteModels';
import InputCombobox from './InputCombobox';

export interface InputAccessProps {
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const AuthTypeSelector: FC<InputAccessProps> = ({ input, index, inputsMap, setInputsMap }) => {
  const authComponent = input.options?.components?.find(
    (component) => component.name === 'auth_type',
  );

  const selectorSettings = authComponent
    ? authComponent
    : // Default auth type settings
      {
        name: 'auth_type',
        default: 'public',
      };

  const selectorOptions: InputOption[] =
    input.options?.components?.find((component) => component.name === 'auth_type')?.options
      ?.list_options ||
    ([
      {
        label: 'Public',
        value: 'public',
      },
      {
        label: 'Confidential Symmetric',
        value: 'symmetric',
      },
      {
        label: 'Confidential Asymmetric',
        value: 'asymmetric',
      },
      {
        label: 'Backend Services',
        value: 'backend_services',
      },
    ] as InputOption[]);

  const selectorModel: TestInput = {
    name: 'auth_type',
    type: 'select',
    title: 'Auth Type',
    description: input.description,
    default: selectorSettings.default || 'public',
    optional: selectorSettings.optional,
    locked: selectorSettings.locked,
    options: {
      list_options: selectorOptions,
    },
  };

  return (
    <InputCombobox
      input={selectorModel}
      index={index}
      inputsMap={inputsMap}
      setInputsMap={setInputsMap}
      key={`input-${index}`}
      disableClear
    />
  );
};

export default AuthTypeSelector;
