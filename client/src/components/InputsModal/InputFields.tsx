import React, { FC } from 'react';
import { List } from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import InputOAuthCredentials from '~/components/InputsModal/InputOAuthCredentials';
import InputCheckboxGroup from '~/components/InputsModal/InputCheckboxGroup';
import InputRadioGroup from '~/components/InputsModal/InputRadioGroup';
import InputTextField from '~/components/InputsModal/InputTextField';
import InputAuth from '~/components/InputsModal/Auth/InputAuth';
import InputSingleCheckbox from '~/components/InputsModal/InputSingleCheckbox';
import InputCombobox from '~/components/InputsModal/InputCombobox';
import InputAccess from '~/components/InputsModal/Auth/InputAccess';

export interface InputFieldsProps {
  inputs: TestInput[];
  inputsMap: Map<string, unknown>;
  setInputsMap: (newInputsMap: Map<string, unknown>, editStatus?: boolean) => void;
}

const InputFields: FC<InputFieldsProps> = ({ inputs, inputsMap, setInputsMap }) => {
  return (
    <List>
      {inputs.map((input: TestInput, index: number) => {
        if (!input.hide) {
          switch (input.type) {
            case 'auth_info':
              if (input.options?.mode === 'auth') {
                return (
                  <InputAuth
                    input={input}
                    index={index}
                    inputsMap={inputsMap}
                    setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                    key={`input-${index}`}
                  />
                );
              }
              return (
                <InputAccess
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
