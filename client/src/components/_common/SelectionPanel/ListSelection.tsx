import React, { FC, useEffect } from 'react';
import { Box, ListItemButton, ListItemText } from '@mui/material';
import useStyles from '~/components/_common/SelectionPanel/styles';
import { ListOption, ListOptionSelection } from '~/models/selectionModels';

export interface ListSelectionProps {
  options: ListOption[];
  selection?: ListOptionSelection;
  setSelection: (option: ListOptionSelection) => void;
}

const ListSelection: FC<ListSelectionProps> = ({
  options,
  selection,
  setSelection: setParentSelection,
}) => {
  const { classes } = useStyles();
  const [selectedListOption, setSelectedListOption] = React.useState('');

  useEffect(() => {
    if (selection) {
      setSelectedListOption(selection);
    }
  }, [selection]);

  const itemClickHandler = (id: string) => {
    setSelectedListOption(id);
    setParentSelection(id);
  };

  return (
    <Box px={2} py={1}>
      {options.map((option) => (
        <ListItemButton
          data-testid="list-option"
          selected={selectedListOption === option.id}
          onClick={() => itemClickHandler(option.id)}
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
