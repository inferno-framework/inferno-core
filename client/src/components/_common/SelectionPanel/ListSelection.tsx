import React, { FC } from 'react';
import { Box, ListItemButton, ListItemText } from '@mui/material';
import useStyles from '~/components/_common/SelectionPanel/styles';
import { ListOption, ListOptionSelection } from '~/models/selectionModels';

export interface ListSelectionProps {
  options: ListOption[];
  setSelection: (option: ListOptionSelection) => void;
}

const ListSelection: FC<ListSelectionProps> = ({ options, setSelection: setParentSelection }) => {
  const { classes } = useStyles();
  const [selectedListOption, setSelectedListOption] = React.useState('');

  const selectOption = (id: string) => {
    setSelectedListOption(id);
    setParentSelection(id);
  };

  return (
    <Box px={2} py={1}>
      {options.map((option) => (
        <ListItemButton
          data-testid="testing-suite-option"
          selected={selectedListOption === option.id}
          onClick={() => selectOption(option.id)}
          classes={{ selected: classes.selectedItem }}
          key={option.id}
        >
          <ListItemText primary={option.title || option.id} />
        </ListItemButton>
      ))}
    </Box>
  );
};

export default ListSelection;
