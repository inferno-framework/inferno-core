import React, { FC } from 'react';
import useStyles from './styles';
import {
  Table,
  TableBody,
  TableRow,
  TableCell,
  Typography,
  TableHead,
  ListItem,
} from '@mui/material';
import { TestInput, TestOutput } from 'models/testSuiteModels';
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
  const styles = useStyles();

  const headerTitles = [headerName, 'Value'];
  const inputOutputsListHeader = (
    <TableRow key="msg-header">
      {headerTitles.map((title) => (
        <TableCell key={title} className={title === 'Value' ? styles.messageMessage : ''}>
          <Typography variant="overline" className={styles.bolderText}>
            {title}
          </Typography>
        </TableCell>
      ))}
    </TableRow>
  );

  const inputOutputsListItems = inputOutputs.map(
    (inputOutputs: TestInput | TestOutput, index: number) => {
      return (
        <TableRow key={`msgRow-${index}`}>
          <TableCell>
            <Typography variant="subtitle2" component="p" className={styles.bolderText}>
              {inputOutputs.name}
            </Typography>
          </TableCell>
          <TableCell className={styles.messageMessage}>
            <ReactMarkdown>{(inputOutputs?.value as string) || ''}</ReactMarkdown>
          </TableCell>
        </TableRow>
      );
    }
  );

  return inputOutputs.length > 0 ? (
    <Table>
      <TableHead>{inputOutputsListHeader}</TableHead>
      <TableBody>{inputOutputsListItems}</TableBody>
    </Table>
  ) : (
    <ListItem>
      <Typography variant="subtitle2" component="p">
        {noValuesMessage || ''}
      </Typography>
    </ListItem>
  );
};

export default InputsOutputsList;
