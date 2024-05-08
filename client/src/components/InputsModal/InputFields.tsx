import React, { FC } from 'react';
import { List } from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import InputOAuthCredentials from '~/components/InputsModal/InputOAuthCredentials';
import InputCheckboxGroup from '~/components/InputsModal/InputCheckboxGroup';
import InputRadioGroup from '~/components/InputsModal/InputRadioGroup';
import InputTextField from '~/components/InputsModal/InputTextField';

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
            return (
              <InputCheckboxGroup
                requirement={requirement}
                index={index}
                inputsMap={inputsMap}
                setInputsMap={(newInputsMap, editStatus) => setInputsMap(newInputsMap, editStatus)}
                key={`input-${index}`}
              />
            );
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
