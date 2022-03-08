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
  Tabs,
  Tab,
  TextField,
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

  const [inputType, setInputType] = React.useState<string>('field');
  const [serialType, setSerialType] = React.useState<string>('JSON');
  const [invalidSerial, setInvalidSerial] = React.useState<boolean>(false);
  const [visibleInput, setVisibleInput] = React.useState<string>('');
  const [visibleInputChange, setVisibleInputChange] = React.useState<string>('');

  useEffect(() => {
    const serialObject = inputs.map((requirement: TestInput) => {
      if (requirement.type == 'oauth_credentials') {
        return {
          ...requirement,
          value: JSON.parse((inputsMap.get(requirement.name) as string) || '{}'),
        };
      } else if (requirement.type == 'radio') {
        const firstValue =
          requirement.options?.list_options && requirement.options?.list_options?.length > 0
            ? requirement.options?.list_options[0]?.value
            : '';
        return {
          ...requirement,
          value: inputsMap.get(requirement.name) || requirement.default || firstValue,
        };
      } else {
        return { ...requirement, value: inputsMap.get(requirement.name) };
      }
    });
    setVisibleInput(
      serialType == 'JSON' ? JSON.stringify(serialObject, null, 3) : YAML.dump(serialObject)
    );
  }, [inputsMap, inputType]);

  function validateSerial(serialChange: string, serialType: string) {
    try {
      if (serialType == 'JSON') {
        JSON.parse(serialChange);
      } else {
        if (YAML.load(serialChange) == undefined) {
          throw new TypeError();
        }
      }
      setInvalidSerial(false);
      return true;
    } catch (e) {
      setInvalidSerial(true);
      return false;
    }
  }

  function handleSerialChange(serialChange: string): void {
    if (validateSerial(serialChange, serialType)) {
      const changes = serialType == 'JSON' ? JSON.parse(serialChange) : YAML.load(serialChange);
      if (changes.keys == undefined) return;
      changes.forEach((change: any) => {
        if (!change.locked) inputsMap.set(change.name, change.value);
      });
      setInputsMap(new Map(inputsMap));
    }
  }

  function handleSerialTypeChange() {
    const type = serialType == 'JSON' ? 'YAML' : 'JSON';
    setSerialType(type);
    if (visibleInputChange) {
      validateSerial(visibleInputChange, type);
    } else {
      validateSerial(visibleInput, type);
    }
  }

  function hideModalWrapper() {
    setInputType('field');
    setInvalidSerial(false);
    hideModal();
  }

  return (
    <Dialog open={modalVisible} onClose={hideModalWrapper} fullWidth maxWidth="sm">
      <DialogTitle>{title}</DialogTitle>
      <Tabs
        value={inputType}
        onChange={(event, value) => {
          setInvalidSerial(false);
          setInputType(value);
        }}
      >
        <Tab value={'field'} label="Input Fields" />
        <Tab value={'serial'} label="Serial Input" />
      </Tabs>
      <DialogContent>
        <DialogContentText component="div">
          <ReactMarkdown>
            {instructions +
              (inputType == 'serial'
                ? ' This serial input accepts field inputs as a valid JSON or YAML entry. All required inputs must have a value and any changes to locked or non-value inputs will not be saved.'
                : '')}
          </ReactMarkdown>
        </DialogContentText>
        {inputType == 'field' && <List>{inputFields}</List>}
        {inputType == 'serial' && (
          <TextField
            className={styles.serialInput}
            fullWidth
            multiline
            error={invalidSerial}
            label={invalidSerial ? `ERROR: INVALID ${serialType}.` : ''}
            defaultValue={visibleInput}
            onChange={(event) => {
              event.preventDefault();
              setVisibleInputChange(event.target.value);
              handleSerialChange(event.target.value);
            }}
          />
        )}
      </DialogContent>
      <DialogActions className={styles.dialogActions}>
        {inputType == 'serial' && (
          <Button className={styles.serialTypeButton} onClick={handleSerialTypeChange}>
            {serialType}
          </Button>
        )}
        <Button color="primary" onClick={hideModalWrapper} data-testid="cancel-button" className={styles.inputAction}>
          Cancel
        </Button>
        <Button
          color="primary"
          onClick={submitClicked}
          disabled={missingRequiredInput || invalidSerial}
          className={styles.inputAction}
        >
          Submit
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default InputsModal;
