import React, { FC } from 'react';
import useStyles from './styles';
import { Table, TableBody, TableRow, TableCell, Typography, TableHead, Box } from '@mui/material';
import { TestInput, TestOutput } from '~/models/testSuiteModels';

interface InputOutputListProps {
  values: TestInput[] | TestOutput[];
  noValuesMessage?: string;
  headerName: string;
}

const InputOutputList: FC<InputOutputListProps> = ({ values, noValuesMessage, headerName }) => {
  const { classes } = useStyles();

  const headerTitles = [headerName, 'Value'];
  const inputOutputsListHeader = (
    <TableRow key="inputOutputs-header">
      {headerTitles.map((title) => (
        <TableCell
          key={title}
          className={title === 'Value' ? classes.inputOutputsValue : classes.noPrintSpacing || ''}
        >
          <Typography variant="overline" className={classes.bolderText}>
            {title}
          </Typography>
        </TableCell>
      ))}
    </TableRow>
  );

  const valuesListItems = values.map((value: TestInput | TestOutput, index: number) => {
    return (
      <TableRow key={`inputOutputsRow-${index}`}>
        <TableCell className={classes.noPrintSpacing}>
          <Typography variant="subtitle2" component="p" className={classes.bolderText}>
            {value.name}
          </Typography>
        </TableCell>
        <TableCell className={classes.inputOutputsValue}>
          <Typography variant="subtitle2" component="p">
            {(value?.value as string) || ''}
          </Typography>
        </TableCell>
      </TableRow>
    );
  });

  const output =
    values.length > 0 ? (
      <Table size="small">
        <TableHead>{inputOutputsListHeader}</TableHead>
        <TableBody>{valuesListItems}</TableBody>
      </Table>
    ) : (
      noValuesMessage && (
        <Box p={2}>
          <Typography variant="subtitle2" component="p">
            {noValuesMessage}
          </Typography>
        </Box>
      )
    );

  return output || <></>;
};

export default InputOutputList;
