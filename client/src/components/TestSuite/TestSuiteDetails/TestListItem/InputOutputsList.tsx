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
    <TableRow key="inputOutputs-header">
      {headerTitles.map((title) => (
        <TableCell key={title} className={title === 'Value' ? styles.inputOutputsValue : ''}>
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
        <TableRow key={`inputOutputsRow-${index}`}>
          <TableCell>
            <Typography variant="subtitle2" component="p" className={styles.bolderText}>
              {inputOutputs.name}
            </Typography>
          </TableCell>
          <TableCell className={styles.inputOutputsValue}>
            <ReactMarkdown>{(inputOutputs?.value as string) || ''}</ReactMarkdown>
          </TableCell>
        </TableRow>
      );
    }
  );

  const output =
    inputOutputs.length > 0 ? (
      <Table>
        <TableHead>{inputOutputsListHeader}</TableHead>
        <TableBody>{inputOutputsListItems}</TableBody>
      </Table>
    ) : (
      noValuesMessage && (
        <ListItem>
          <Typography variant="subtitle2" component="p">
            {noValuesMessage}
          </Typography>
        </ListItem>
      )
    );

  return output || <></>;
};

export default InputsOutputsList;
