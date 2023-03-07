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
  Typography,
} from '@mui/material';
import { OAuthCredentials, RunnableType, TestInput } from '~/models/testSuiteModels';
import InputRadioGroup from './InputRadioGroup';
import ReactMarkdown from 'react-markdown';
import InputTextArea from './InputTextArea';
import InputTextField from './InputTextField';
import InputOAuthCredentials from './InputOAuthCredentials';
import YAML from 'js-yaml';
import InputCheckboxGroup from './InputCheckboxGroup';

export interface InputsModalProps {
  runnableType: RunnableType;
  runnableId: string;
  title: string;
  inputInstructions?: string;
  inputs: TestInput[];
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
  hideModal,
  createTestRun,
  sessionData,
}) => {
  const styles = useStyles();
  const [open, setOpen] = React.useState<boolean>(true);
  const [inputsMap, setInputsMap] = React.useState<Map<string, unknown>>(new Map());
  const [inputType, setInputType] = React.useState<string>('Field');
  const [baseInput, setBaseInput] = React.useState<string>('');
  const [invalidInput, setInvalidInput] = React.useState<boolean>(false);
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

  useEffect(() => {
    setInvalidInput(false);
    setBaseInput(serializeMap(inputsMap));
  }, [inputType, open]);

  const handleSubmitKeydown = (e: React.KeyboardEvent<HTMLDivElement>) => {
    if (
      open &&
      e.key === 'Enter' &&
      (e.metaKey || e.ctrlKey) &&
      !missingRequiredInput &&
      !invalidInput
    ) {
      submitClicked();
    }
  };

  const submitClicked = () => {
    const inputs_with_values: TestInput[] = [];
    inputsMap.forEach((input_value, input_name) => {
      inputs_with_values.push({ name: input_name, value: input_value, type: 'text' });
    });
    createTestRun(runnableType, runnableId, inputs_with_values);
    closeModal();
  };

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
      case 'checkbox':
        return (
          <InputCheckboxGroup
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

  const serializeMap = (map: Map<string, unknown>): string => {
    const flatObj = inputs.map((requirement: TestInput) => {
      if (requirement.type === 'oauth_credentials') {
        return {
          ...requirement,
          value: JSON.parse((map.get(requirement.name) as string) || '{}') as OAuthCredentials,
        };
      } else if (requirement.type === 'radio') {
        const firstVal =
          requirement.options?.list_options && requirement.options?.list_options?.length > 0
            ? requirement.options?.list_options[0]?.value
            : '';
        return {
          ...requirement,
          value: map.get(requirement.name) || requirement.default || firstVal,
        };
      } else {
        return { ...requirement, value: map.get(requirement.name) || '' };
      }
    });
    return inputType === 'JSON' ? JSON.stringify(flatObj, null, 3) : YAML.dump(flatObj);
  };

  const handleInputTypeChange = (e: React.MouseEvent, value: string) => {
    if (value !== null) setInputType(value);
  };

  const parseSerialChanges = (changes: string): TestInput[] | undefined => {
    let parsed: TestInput[];
    try {
      if (inputType === 'JSON') {
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

  const closeModal = () => {
    setOpen(false);
    hideModal();
  };

  return (
    <Dialog
      open={open}
      fullWidth
      maxWidth="sm"
      onKeyDown={handleSubmitKeydown}
      onClose={closeModal}
    >
      {/* a11y workaround until MUI implements component prop in DialogTitle */}
      <DialogTitle {...({ component: 'div' } as unknown)}>
        <Typography component="h1" variant="h6">
          {title}
        </Typography>
      </DialogTitle>
      <DialogContent>
        <main>
          <DialogContentText component="div">
            <ReactMarkdown>
              {instructions +
                (inputType === 'Field'
                  ? ''
                  : ' In this view, only changes to the value attribute of an element will be saved. Further, only elements with names that match an input defined for the current suite, group, or test will be saved. The intended use of this view is to provide a template for users to copy/paste in order to avoid filling out individual fields every time.')}
            </ReactMarkdown>
          </DialogContentText>
          {inputType === 'Field' ? (
            <List>{inputFields}</List>
          ) : (
            <TextField
              id={`${inputType}-serial-input`}
              fullWidth
              multiline
              minRows={4}
              key={baseInput}
              error={invalidInput}
              defaultValue={baseInput}
              data-testid="serial-input"
              className={styles.serialInput}
              onChange={(e) => handleSerialChanges(e.target.value)}
              label={invalidInput ? `ERROR: INVALID ${inputType}` : inputType}
            />
          )}
        </main>
      </DialogContent>
      <DialogActions className={styles.dialogActions}>
        <ToggleButtonGroup
          exclusive
          role="group"
          color="primary"
          size="small"
          value={inputType}
          onChange={handleInputTypeChange}
          className={styles.toggleButtonGroup}
        >
          <ToggleButton
            value="Field"
            disabled={invalidInput}
            data-testid="field-button"
            className={styles.toggleButton}
          >
            Field
          </ToggleButton>
          <ToggleButton
            value="JSON"
            disabled={invalidInput}
            data-testid="json-button"
            className={styles.toggleButton}
          >
            JSON
          </ToggleButton>
          <ToggleButton
            value="YAML"
            disabled={invalidInput}
            data-testid="yaml-button"
            className={styles.toggleButton}
          >
            YAML
          </ToggleButton>
        </ToggleButtonGroup>
        <Button data-testid="cancel-button" className={styles.inputAction} onClick={closeModal}>
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
