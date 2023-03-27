import React, { FC } from 'react';
import useStyles from './styles';
import { Table, TableBody, TableRow, TableCell, Typography, TableHead, Box } from '@mui/material';
import { TestInput, TestOutput } from '~/models/testSuiteModels';
import ReactMarkdown from 'react-markdown';

interface InputOutputsListProps {
  inputOutputs: TestInput[] | TestOutput[];
  noValuesMessage?: string;
  headerName: string;
}

const InputsOutputsList: FC<InputOutputsListProps> = ({
  inputOutputs,
  noValuesMessage,
  headerName,
}) => {
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

  const inputOutputsListItems = inputOutputs.map(
    (inputOutputs: TestInput | TestOutput, index: number) => {
      return (
        <TableRow key={`inputOutputsRow-${index}`}>
          <TableCell className={classes.noPrintSpacing}>
            <Typography variant="subtitle2" component="p" className={classes.bolderText}>
              {inputOutputs.name}
            </Typography>
          </TableCell>
          <TableCell className={classes.inputOutputsValue}>
            <ReactMarkdown className={classes.wordWrap}>
              {(inputOutputs?.value as string) || ''}
            </ReactMarkdown>
          </TableCell>
        </TableRow>
      );
    }
  );

  const output =
    inputOutputs.length > 0 ? (
      <Table size="small">
        <TableHead>{inputOutputsListHeader}</TableHead>
        <TableBody>{inputOutputsListItems}</TableBody>
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

export default InputsOutputsList;
