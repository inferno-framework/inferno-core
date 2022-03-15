import React, { FC, useEffect } from 'react';
import useStyles from './styles';
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  List,
  TextField,
  ToggleButtonGroup,
  ToggleButton,
} from '@mui/material';
import { OAuthCredentials, RunnableType, TestInput } from 'models/testSuiteModels';
import InputRadioGroup from './InputsRadioGroup';
import ReactMarkdown from 'react-markdown';
import InputTextArea from './InputTextArea';
import InputTextField from './InputTextField';
import InputOAuthCredentials from './InputOAuthCredentials';
import YAML from 'js-yaml';
export interface InputsModalProps {
  runnableType: RunnableType;
  runnableId: string;
  title: string;
  inputInstructions?: string;
  inputs: TestInput[];
  modalVisible: boolean;
  hideModal: () => void;
  createTestRun: (runnableType: RunnableType, runnableId: string, inputs: TestInput[]) => void;
  sessionData: Map<string, unknown>;
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
  title,
  inputInstructions,
  inputs,
  modalVisible,
  hideModal,
  createTestRun,
  sessionData,
}) => {
  const styles = useStyles();
  const [inputsMap, setInputsMap] = React.useState<Map<string, unknown>>(new Map());
  const missingRequiredInput = inputs.some((input: TestInput) => {
    let oAuthMissingRequiredInput = false;
    try {
      // if input has OAuth, check if required values are filled
      const oAuthJSON = JSON.parse(inputsMap.get(input.name) as string) as OAuthCredentials;
      const accessTokenIsEmpty = oAuthJSON.access_token === '';
      const refreshIsEmpty =
        oAuthJSON.refresh_token !== '' &&
        (oAuthJSON.token_url === '' || oAuthJSON.client_id === '');
      oAuthMissingRequiredInput = (accessTokenIsEmpty && !input.optional) || refreshIsEmpty;
    } catch (e) {
      // if JSON.parse fails, then assume field is not OAuth and move on
    }
    if (input.type === 'radio') return false; // radio inputs will always be required and have a default value
    return (!input.optional && !inputsMap.get(input.name)) || oAuthMissingRequiredInput;
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
      inputsMap.set(
        requirement.name,
        sessionData.get(requirement.name) || (requirement.default as string) || ''
      );
    });
    setInputsMap(new Map(inputsMap));
  }, [inputs, sessionData]);

  const instructions =
    inputInstructions ||
    `Please fill out required fields in order to run the ${runnableTypeReadable(runnableType)}.`;

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
      case 'radio':
        return (
          <InputRadioGroup
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

  const [inputType, setInputType] = React.useState<string>('Field');
  const [baseInput, setBaseInput] = React.useState<string>('');
  const [invalidInput, setInvalidInput] = React.useState<boolean>(false);

  useEffect(() => {
    const serialObj = inputs.map((requirement: TestInput) => {
      if (requirement.type == 'oauth_credentials') {
        return {
          ...requirement,
          value:
            (JSON.parse(inputsMap.get(requirement.name) as string) as OAuthCredentials) || '{}',
        };
      } else if (requirement.type == 'radio') {
        const firstVal =
          requirement.options?.list_options && requirement.options?.list_options?.length > 0
            ? requirement.options?.list_options[0]?.value
            : '';
        return {
          ...requirement,
          value: inputsMap.get(requirement.name) || requirement.default || firstVal,
        };
      } else {
        return { ...requirement, value: inputsMap.get(requirement.name) || '' };
      }
    });
    setBaseInput(inputType == 'JSON' ? JSON.stringify(serialObj, null, 3) : YAML.dump(serialObj));
  }, [inputType]);

  const handleInputTypeChange = (e: React.MouseEvent, value: string) => {
    if (value !== null) {
      setInputType(value);
    }
  };

  const handleSerialChanges = (serialChanges: string) => {
    const parsedChanges = parseSerialChanges(serialChanges);
    if (parsedChanges !== undefined && parsedChanges.keys !== undefined) {
      parsedChanges.forEach((change: TestInput) => {
        if (!change.locked && change.value !== undefined)
          inputsMap.set(change.name, change.value || '');
      });
    }
    setInputsMap(new Map(inputsMap));
  };

  function parseSerialChanges(changes: string): TestInput[] | undefined {
    let parsed: TestInput[];
    try {
      if (inputType == 'JSON') {
        parsed = JSON.parse(changes) as TestInput[];
      } else {
        parsed = YAML.load(changes) as TestInput[];
      }
      setInvalidInput(false);
      return parsed;
    } catch (e) {
      setInvalidInput(true);
      return undefined;
    }
  }

  return (
    <Dialog
      open={modalVisible}
      fullWidth
      maxWidth="sm"
      onClose={() => {
        hideModal();
        setInvalidInput(false);
      }}
    >
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        <DialogContentText component="div">
          <ReactMarkdown>{instructions}</ReactMarkdown>
        </DialogContentText>
        {inputType == 'Field' ? (
          <List>{inputFields}</List>
        ) : (
          <TextField
            fullWidth
            multiline
            minRows={4}
            key={baseInput}
            error={invalidInput}
            label={invalidInput ? `ERROR: INVALID ${inputType}` : ''}
            defaultValue={baseInput}
            className={styles.serialInput}
            onChange={(e) => {
              handleSerialChanges(e.target.value);
            }}
          />
        )}
      </DialogContent>
      <DialogActions className={styles.dialogActions}>
        <ToggleButtonGroup
          exclusive
          value={inputType}
          className={styles.toggleButtonGroup}
          onChange={handleInputTypeChange}
        >
          <ToggleButton value="Field" className={styles.toggleButton} disabled={invalidInput}>
            Field
          </ToggleButton>
          <ToggleButton value="JSON" className={styles.toggleButton} disabled={invalidInput}>
            JSON
          </ToggleButton>
          <ToggleButton value="YAML" className={styles.toggleButton} disabled={invalidInput}>
            YAML
          </ToggleButton>
        </ToggleButtonGroup>
        <Button
          data-testid="cancel-button"
          className={styles.inputAction}
          onClick={() => {
            hideModal();
            setInvalidInput(false);
            setInputType('Field');
          }}
        >
          Cancel
        </Button>
        <Button
          onClick={submitClicked}
          disabled={missingRequiredInput || invalidInput}
          className={styles.inputAction}
        >
          Submit
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default InputsModal;
