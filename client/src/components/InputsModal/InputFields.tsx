import React, { FC } from 'react';
import { List } from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import InputOAuthCredentials from '~/components/InputsModal/InputOAuthCredentials';
import InputCheckboxGroup from '~/components/InputsModal/InputCheckboxGroup';
import InputRadioGroup from '~/components/InputsModal/InputRadioGroup';
import InputTextField from '~/components/InputsModal/InputTextField';
import InputAuth from './InputAuth';
import InputSingleCheckbox from './InputSingleCheckbox';

export interface InputFieldsProps {
  inputs: TestInput[];
  inputsMap: Map<string, unknown>;
  setInputsMap: (newInputsMap: Map<string, unknown>, editStatus?: boolean) => void;
}

const InputFields: FC<InputFieldsProps> = ({ inputs, inputsMap, setInputsMap }) => {
  return (
    <List>
      {inputs.map((requirement: TestInput, index: number) => {
        switch (requirement.type) {
          case 'auth_info':
            return (
              <InputAuth
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
            console.log(requirement);

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
      })}
    </List>
  );
};

export default InputFields;
