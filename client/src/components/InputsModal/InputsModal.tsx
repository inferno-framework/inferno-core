import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  List,
} from '@material-ui/core';
import { RunnableType, TestInput } from 'models/testSuiteModels';
import React, { FC, useEffect } from 'react';
import InputTextArea from './InputTextArea';
import InputTextField from './InputTextField';
import InputOAuthCredentials from './InputOAuthCredentials';

export interface InputsModalProps {
  runnableType: RunnableType;
  runnableId: string;
  inputs: TestInput[];
  modalVisible: boolean;
  hideModal: () => void;
  createTestRun: (runnableType: RunnableType, runnableId: string, inputs: TestInput[]) => void;
}

function runnableTypeReadable(runnableType: RunnableType) {
  switch (runnableType) {
    case RunnableType.TestSuite:
      return 'test suite';
    case RunnableType.TestGroup:
      return 'test group';
    case RunnableType.Test:
      return 'test';
  }
}

const InputsModal: FC<InputsModalProps> = ({
  runnableType,
  runnableId,
  inputs,
  modalVisible,
  hideModal,
  createTestRun,
}) => {
  const [inputsMap, setInputsMap] = React.useState<Map<string, string>>(new Map());
  const missingRequiredInput = inputs.some((input: TestInput) => {
    return !input.optional && inputsMap.get(input.name)?.length == 0;
  });
  function submitClicked(): void {
    const inputs_with_values =
      inputs
        .filter(input => inputsMap.has(input.name))
        .map(input => ({ name: input.name, value: inputsMap.get(input.name), type: input.type }))
    createTestRun(runnableType, runnableId, inputs_with_values);
    hideModal();
  }

  useEffect(() => {
    inputsMap.clear();
    inputs.forEach((requirement: TestInput) => {
      inputsMap.set(requirement.name, requirement.value || '');
    });
    setInputsMap(new Map(inputsMap));
  }, [inputs]);

  const inputFields = inputs.map((requirement: TestInput, index: number) => {
    switch (requirement.type) {
      case 'oauth_credentials':
        return (
          <InputOAuthCredentials
            requirement={requirement}
            index={index}
            inputsMap={inputsMap}
            setInputsMap={setInputsMap}
            key={`input-${index}`}
          />
        );
      case 'textarea':
        return (
          <InputTextArea
            requirement={requirement}
            index={index}
            inputsMap={inputsMap}
            setInputsMap={setInputsMap}
            key={`input-${index}`}
          />
        );
      default:
        return (
          <InputTextField
            requirement={requirement}
            index={index}
            inputsMap={inputsMap}
            setInputsMap={setInputsMap}
            key={`input-${index}`}
          />
        );
    }
  });
  return (
    <Dialog open={modalVisible} onClose={() => hideModal()} fullWidth={true} maxWidth="sm">
      <DialogTitle>Test Inputs</DialogTitle>
      <DialogContent>
        <DialogContentText>
          Please fill out required fields in order to run the {runnableTypeReadable(runnableType)}.
        </DialogContentText>
        <List>{inputFields}</List>
      </DialogContent>
      <DialogActions>
        <Button color="primary" onClick={() => hideModal()} data-testid="cancel-button">
          Cancel
        </Button>
        <Button color="primary" onClick={() => submitClicked()} disabled={missingRequiredInput}>
          Submit
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default InputsModal;
