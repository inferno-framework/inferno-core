import React, { FC } from 'react';
import { List } from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import InputAuth from '~/components/InputsModal/Auth/InputAuth';
import InputCheckboxGroup from '~/components/InputsModal/InputCheckboxGroup';
import InputCombobox from '~/components/InputsModal/InputCombobox';
import InputOAuthCredentials from '~/components/InputsModal/InputOAuthCredentials';
import InputRadioGroup from '~/components/InputsModal/InputRadioGroup';
import InputSingleCheckbox from '~/components/InputsModal/InputSingleCheckbox';
import InputTextField from '~/components/InputsModal/InputTextField';

export interface InputFieldsProps {
  inputs: TestInput[];
  inputsMap: Map<string, unknown>;
  setInputsMap: (newInputsMap: Map<string, unknown>, editStatus?: boolean) => void;
}

const InputFields: FC<InputFieldsProps> = ({ inputs, inputsMap, setInputsMap }) => {
  return (
    <List>
      {inputs.map((input: TestInput, index: number) => {
        if (!input.hidden) {
          switch (input.type) {
            case 'auth_info':
              if (input.options?.mode === 'auth') {
                return (
                  <InputAuth
                    mode={input.options?.mode}
                    input={input}
                    index={index}
                    inputsMap={inputsMap}
                    setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                    key={`input-${index}`}
                  />
                );
              }
              return (
                <InputAuth
                  mode="access"
                  input={input}
                  index={index}
                  inputsMap={inputsMap}
                  setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                  key={`input-${index}`}
                />
              );
            case 'oauth_credentials':
              return (
                <InputOAuthCredentials
                  input={input}
                  index={index}
                  inputsMap={inputsMap}
                  setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                  key={`input-${index}`}
                />
              );
            case 'checkbox':
              if (input.options?.list_options?.length) {
                return (
                  <InputCheckboxGroup
                    input={input}
                    index={index}
                    inputsMap={inputsMap}
                    setInputsMap={(newInputsMap, editStatus) =>
                      setInputsMap(newInputsMap, editStatus)
                    }
                    key={`input-${index}`}
                  />
                );
              } else {
                // if no options listed then assume single checkbox input
                return (
                  <InputSingleCheckbox
                    input={input}
                    index={index}
                    inputsMap={inputsMap}
                    setInputsMap={(newInputsMap, editStatus) =>
                      setInputsMap(newInputsMap, editStatus)
                    }
                    key={`input-${index}`}
                  />
                );
              }
            case 'radio':
              return (
                <InputRadioGroup
                  input={input}
                  index={index}
                  inputsMap={inputsMap}
                  setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                  key={`input-${index}`}
                />
              );
            case 'select':
              return (
                <InputCombobox
                  input={input}
                  index={index}
                  inputsMap={inputsMap}
                  setInputsMap={(newInputsMap, editStatus) =>
                    setInputsMap(newInputsMap, editStatus)
                  }
                  key={`input-${index}`}
                />
              );
            default:
              return (
                <InputTextField
                  input={input}
                  index={index}
                  inputsMap={inputsMap}
                  setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                  key={`input-${index}`}
                />
              );
          }
        }
      })}
    </List>
  );
};

export default InputFields;
