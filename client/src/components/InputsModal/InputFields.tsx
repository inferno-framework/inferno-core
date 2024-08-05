import React, { FC } from 'react';
import { List } from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import InputOAuthCredentials from '~/components/InputsModal/InputOAuthCredentials';
import InputCheckboxGroup from '~/components/InputsModal/InputCheckboxGroup';
import InputRadioGroup from '~/components/InputsModal/InputRadioGroup';
import InputTextField from '~/components/InputsModal/InputTextField';
import InputAuth from '~/components/InputsModal/InputAuth';
import InputSingleCheckbox from '~/components/InputsModal/InputSingleCheckbox';
import InputCombobox from '~/components/InputsModal/InputCombobox';
import InputAccess from '~/components/InputsModal/InputAccess';

export interface InputFieldsProps {
  inputs: TestInput[];
  inputsMap: Map<string, unknown>;
  setInputsMap: (newInputsMap: Map<string, unknown>, editStatus?: boolean) => void;
}

const InputFields: FC<InputFieldsProps> = ({ inputs, inputsMap, setInputsMap }) => {
  return (
    <List>
      {inputs.map((requirement: TestInput, index: number) => {
        if (!requirement.hide) {
          switch (requirement.type) {
            case 'auth_info':
              if (requirement.options?.mode === 'auth') {
                return (
                  <InputAuth
                    requirement={requirement}
                    index={index}
                    inputsMap={inputsMap}
                    setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                    key={`input-${index}`}
                  />
                );
              }
              return (
                <InputAccess
                  requirement={requirement}
                  index={index}
                  inputsMap={inputsMap}
                  setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                  key={`input-${index}`}
                />
              );
            case 'oauth_credentials':
              return (
                <InputOAuthCredentials
                  requirement={requirement}
                  index={index}
                  inputsMap={inputsMap}
                  setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                  key={`input-${index}`}
                />
              );
            case 'checkbox':
              if (requirement.options?.list_options?.length) {
                return (
                  <InputCheckboxGroup
                    requirement={requirement}
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
                    requirement={requirement}
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
                  requirement={requirement}
                  index={index}
                  inputsMap={inputsMap}
                  setInputsMap={(newInputsMap) => setInputsMap(newInputsMap)}
                  key={`input-${index}`}
                />
              );
            case 'select':
              return (
                <InputCombobox
                  requirement={requirement}
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
                  requirement={requirement}
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
