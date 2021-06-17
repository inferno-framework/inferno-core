import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  List,
  ListItem,
  TextField,
} from '@material-ui/core';
import { RunnableType, TestInput } from 'models/testSuiteModels';
import React, { FC } from 'react';

export interface InputsModalProps {
  runnableType: RunnableType;
  runnableId: string;
  inputs: TestInput[];
  modalVisible: boolean;
  testSessionId: string;
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
  testSessionId,
  runnableType,
  runnableId,
  inputs,
  modalVisible,
  hideModal,
  createTestRun,
}) => {
  function submitClicked(): void {
    switch (runnableType) {
      case RunnableType.TestSuite:
        console.log(`create test run for session: ${testSessionId}, testSuite: ${runnableId}`);
        break;
      case RunnableType.TestGroup:
        console.log(`create test run for session: ${testSessionId}, testGroup: ${runnableId}`);
        break;
      case RunnableType.Test:
        console.log(`create test run for session: ${testSessionId}, test: ${runnableId}`);
        break;
    }
    const inputs_with_values: TestInput[] = [];
    inputsMap.forEach((input_value, input_name) => {
      inputs_with_values.push({ name: input_name, value: input_value });
    });
    createTestRun(runnableType, runnableId, inputs_with_values);
    hideModal();
  }
  const [inputsMap, setInputsMap] = React.useState<Map<string, string>>(new Map());

  const inputFields = inputs.map((requirement: TestInput, index: number) => {
    console.log(requirement.name);
    return (
      <ListItem key={`requirement${index}`}>
        <TextField
          id={`requirement${index}_input`}
          fullWidth
          label={requirement.title}
          value={inputsMap.get(requirement.name) || ''}
          onChange={(event) => {
            const value = event.target.value;
            inputsMap.set(requirement.name, value);
            setInputsMap(new Map(inputsMap));
          }}
        />
      </ListItem>
    );
  });
  return (
    <Dialog open={modalVisible} onClose={() => hideModal()}>
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
        <Button color="primary" onClick={() => submitClicked()}>
          Submit
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default InputsModal;
