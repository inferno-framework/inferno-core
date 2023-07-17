import React, { FC, useEffect } from 'react';
import { Box, FormControl, FormControlLabel, FormLabel, Radio, RadioGroup } from '@mui/material';
import HelpOutlineOutlinedIcon from '@mui/icons-material/HelpOutlineOutlined';
import { RadioOption, RadioOptionSelection } from '~/models/selectionModels';
import CustomTooltip from '~/components/_common/CustomTooltip';

export interface RadioSelectionProps {
  options: RadioOption[];
  setSelections: (options: RadioOptionSelection[]) => void;
}

const RadioSelection: FC<RadioSelectionProps> = ({
  options,
  setSelections: setParentSelections,
}) => {
  const initialSelectedRadioOptions: RadioOptionSelection[] = options.map((option) => ({
    // just grab the first to start
    // perhaps choices should be persisted in the URL to make it easy to share specific options
    id: option.id,
    value: option && option.list_options ? option.list_options[0].value : '',
  }));
  const [selectedRadioOptions, setSelectedRadioOptions] = React.useState<RadioOptionSelection[]>(
    initialSelectedRadioOptions || []
  );

  useEffect(() => {
    setParentSelections(initialSelectedRadioOptions);
  }, []);

  const changeRadioOption = (option_id: string, value: string): void => {
    const newOptions = selectedRadioOptions.map((option: RadioOptionSelection) =>
      option.id === option_id ? { id: option.id, value: value } : { ...option }
    );
    setSelectedRadioOptions(newOptions);
    setParentSelections(newOptions);
  };

  // Given an option and index i, returns a RadioGroup with a RadioButton per choice
  return (
    <Box px={4} py={2}>
      {options.map((option, i) => (
        <FormControl fullWidth id={`radio-input-${i}`} key={`radio-form-control${i}`}>
          <FormLabel sx={{ display: 'flex', alignItems: 'center' }}>
            {option.title || option.id}
            {option.description && (
              <CustomTooltip title={option.description}>
                <HelpOutlineOutlinedIcon fontSize="small" color="secondary" sx={{ px: 0.5 }} />
              </CustomTooltip>
            )}
          </FormLabel>

          <RadioGroup
            aria-label={`radio-group-${option.id}`}
            defaultValue={
              option.list_options && option.list_options.length && option.list_options[0].value
            }
            name={`radio-group-${option.id}`}
            data-testid="radio-option-group"
          >
            {option?.list_options?.map((choice, k) => (
              <FormControlLabel
                value={choice.value}
                control={<Radio size="small" data-testid="radio-option-button" />}
                label={choice.label}
                key={`radio-button-${k}`}
                onClick={() => {
                  changeRadioOption(option.id, choice.value);
                }}
              />
            ))}
          </RadioGroup>
        </FormControl>
      ))}
    </Box>
  );
};

export default RadioSelection;
