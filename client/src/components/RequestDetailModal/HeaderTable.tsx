import { Paper, Table, TableBody, TableCell, TableContainer, TableRow } from '@material-ui/core';
import { RequestHeader } from 'models/testSuiteModels';
import React, { FC } from 'react';
import useStyles from './styles';

export interface HeaderTableProps {
  headers: RequestHeader[];
}

const HeaderTable: FC<HeaderTableProps> = ({ headers }) => {
  const styles = useStyles();
  return (
    <TableContainer component={Paper} variant="outlined">
      <Table size="small">
        <TableBody>
          {headers.map((header) => (
            <TableRow key={header.name}>
              <TableCell className={styles.headerName} component="th" scope="row">
                {header.name}:
              </TableCell>
              <TableCell align="left">{header.value}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
};

export default HeaderTable;
