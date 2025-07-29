import React, { FC } from 'react';
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  TextField,
  MenuItem,
} from '@mui/material';
import { useSnackbar } from 'notistack';
import { applyPreset } from '~/api/TestSessionApi';
import { PresetSummary } from '~/models/testSuiteModels';
import { useTestSessionStore } from '~/store/testSession';
import theme from '~/styles/theme';
import lightTheme from '~/styles/theme';

export interface PresetsModalProps {
  presets: PresetSummary[];
  testSessionId: string;
  getSessionData: (testSessionId: string) => void;
}

const PresetsSelector: FC<PresetsModalProps> = ({ presets, testSessionId, getSessionData }) => {
  const { enqueueSnackbar } = useSnackbar();
  const readOnly = useTestSessionStore((state) => state.readOnly);
  const null_preset = { id: 'NULL_PRESET', title: 'None' };
  const presetTitleToIdMap: { [key: string]: string } = presets.reduce(
    (reducedObj, preset) => ({ ...reducedObj, [preset.title]: preset.id }),
    {},
  );

  const SHOW_CONFIRMATION_MODAL = false;

  const [presetOptions, setPresetOptions] = React.useState([
    null_preset,
    ...presets.sort((p1, p2) => {
      if (p1.title > p2.title) return 1;
      if (p1.title < p2.title) return -1;
      return 0;
    }),
  ]);
  const [formerPreset, setFormerPreset] = React.useState(null_preset.title);
  const [selectedPreset, setSelectedPreset] = React.useState(null_preset.title);
  const [modalVisible, setModalVisible] = React.useState(false);

  const applyPresetToSession = (presetId: string) => {
    applyPreset(testSessionId, presetId)
      .then(() => {
        getSessionData(testSessionId);
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Could not set preset: ${e.message}`, { variant: 'error' });
      });
  };

  // To be used when the null preset option has no behavior
  const removeNullFromOptions = () => {
    const nullIndex = presetOptions.findIndex((option) => option.id === null_preset.id);
    if (nullIndex >= 0) {
      presetOptions.splice(nullIndex, 1);
      setPresetOptions(presetOptions);
    }
  };

  const handleOnChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.value) {
      setSelectedPreset(e.target.value);
      // Remove when modal is active
      if (!SHOW_CONFIRMATION_MODAL) {
        applyPresetToSession(presetTitleToIdMap[e.target.value]);
      }
    }
    // TODO: Handle clearing old results on preset change
    if (e.target.value && e.target.value !== null_preset.title) {
      if (SHOW_CONFIRMATION_MODAL) {
        setModalVisible(true);
      } else {
        removeNullFromOptions(); // If null preset behavior is added, remove this
        enqueueSnackbar(`${e.target.value} has been set as preset.`, { variant: 'success' });
      }
    }
  };

  return (
    <>
      <TextField
        id="preset-select"
        label="Preset"
        disabled={readOnly}
        size="small"
        fullWidth
        select
        slotProps={{
          inputLabel: {
            sx: { '&.Mui-focused': { color: lightTheme.palette.primary.dark } },
          },
        }}
        value={selectedPreset}
        onChange={handleOnChange}
      >
        {presetOptions.map((option) => (
          <MenuItem key={option.id} value={option.title}>
            {option.title}
          </MenuItem>
        ))}
      </TextField>
      <Dialog open={modalVisible} fullWidth maxWidth="xs">
        <DialogTitle>Are you sure?</DialogTitle>
        <DialogContent>
          Selecting a new preset will clear all existing test results. If you wish to proceed, click
          the Apply Preset button.
        </DialogContent>
        <DialogActions>
          <Button
            data-testid="preset-cancel-button"
            sx={{ color: theme.palette.primary.dark, fontWeight: 'bold' }}
            onClick={() => {
              setSelectedPreset(formerPreset);
              setModalVisible(false);
            }}
          >
            Cancel
          </Button>
          <Button
            data-testid="preset-apply-button"
            sx={{ color: theme.palette.primary.dark, fontWeight: 'bold' }}
            onClick={() => {
              applyPresetToSession(presetTitleToIdMap[selectedPreset]);
              setFormerPreset(selectedPreset);
              setModalVisible(false);
              removeNullFromOptions(); // If null preset behavior is added, remove this
            }}
          >
            Apply Preset
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default PresetsSelector;
