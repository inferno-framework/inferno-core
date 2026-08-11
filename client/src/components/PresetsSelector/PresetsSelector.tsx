import React, { FC } from 'react';
import { TextField, MenuItem } from '@mui/material';
import { useSnackbar } from 'notistack';
import { applyPreset } from '~/api/TestSessionApi';
import { PresetSummary } from '~/models/testSuiteModels';
import { useTestSessionStore } from '~/store/testSession';
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

  const [presetOptions, setPresetOptions] = React.useState([
    null_preset,
    ...presets.sort((p1, p2) => {
      if (p1.title > p2.title) return 1;
      if (p1.title < p2.title) return -1;
      return 0;
    }),
  ]);
  const [selectedPreset, setSelectedPreset] = React.useState(null_preset.title);

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
      applyPresetToSession(presetTitleToIdMap[e.target.value]);
    }
    // TODO: Handle clearing old results on preset change
    if (e.target.value && e.target.value !== null_preset.title) {
      removeNullFromOptions(); // If null preset behavior is added, remove this
      enqueueSnackbar(`${e.target.value} has been set as preset.`, { variant: 'success' });
    }
  };

  return (
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
  );
};

export default PresetsSelector;
