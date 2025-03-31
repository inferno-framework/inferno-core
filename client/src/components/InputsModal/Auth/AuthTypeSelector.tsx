import React, { FC } from 'react';
import { Auth, InputOption, TestInput } from '~/models/testSuiteModels';
import InputCombobox from '~/components/InputsModal/InputCombobox';

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
    authComponent?.options?.list_options ||
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

  // Fetch value from input.value field if it exists
  // Otherwise use, in order, default, then the first available option, then 'public'
  const getAuthStartingValue = () => {
    let startingValue = selectorSettings.default || selectorOptions[0].value || 'public';
    if (input.value && typeof input.value === 'string') {
      const parsedAuth = JSON.parse(input.value) as Auth;
      if (parsedAuth.auth_type) startingValue = parsedAuth.auth_type;
    }
    return startingValue;
  };

  const selectorModel: TestInput = {
    name: 'auth_type',
    type: 'select',
    title: 'Auth Type',
    description: input.description,
    default: getAuthStartingValue(),
    optional: selectorSettings.optional || input.optional,
    locked: selectorSettings.locked || input.locked,
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
