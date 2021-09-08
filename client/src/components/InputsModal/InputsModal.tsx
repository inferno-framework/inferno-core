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
    const inputs_with_values: TestInput[] = [];
    inputsMap.forEach((input_value, input_name) => {
      inputs_with_values.push({ name: input_name, value: input_value, type: 'text' });
    });
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
      case 'textarea':
        return (
<<<<<<< HEAD
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
=======
          <ListItem key={`requirement${index}`} disabled={requirement.locked}>
            <TextField
              disabled={requirement.locked}
              id={`requirement${index}_input`}
              className={styles.inputField}
              fullWidth
              label={requirement.title || requirement.name}
              helperText={requirement.description}
              value={
                (inputsMap.get(requirement.name) ?? '') +
                (requirement.locked ? ' (*locked input)' : '')
              }
              multiline
              rows={4}
              inputProps={{ className: styles.textarea }}
              onChange={(event) => {
                const value = event.target.value;
                inputsMap.set(requirement.name, value);
                setInputsMap(new Map(inputsMap));
              }}
            />
          </ListItem>
        );
      default:
        return (
          <ListItem key={`requirement${index}`} disabled={requirement.locked}>
            <TextField
              disabled={requirement.locked}
              id={`requirement${index}_input`}
              className={styles.inputField}
              fullWidth
              label={requirement.title || requirement.name}
              helperText={requirement.description}
              value={
                (inputsMap.get(requirement.name) ?? '') +
                (requirement.locked ? ' (*locked input)' : '')
              }
              onChange={(event) => {
                const value = event.target.value;
                inputsMap.set(requirement.name, value);
                setInputsMap(new Map(inputsMap));
              }}
            />
          </ListItem>
>>>>>>> ae1094b (Added the 'locked?' attribute to the TestInput interface in testSuiteModels.ts and then modified the InputModal to use that attribute. Also, added an example of 'locked input' to demo suite.)
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
