import React, { FC } from 'react';
import {
  Button,
  Typography,
  TableRow,
  TableCell,
  Table,
  TableContainer,
  TableBody,
  Tooltip,
  TableHead,
  Box,
} from '@mui/material';
import { Request } from 'models/testSuiteModels';
import RequestDetailModal from 'components/RequestDetailModal/RequestDetailModal';
import { getRequestDetails } from 'api/RequestsApi';
import useStyles from './styles';

interface RequestsListProps {
  resultId: string;
  requests: Request[];
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
}

const RequestsList: FC<RequestsListProps> = ({ requests, resultId, updateRequest }) => {
  const [showDetails, setShowDetails] = React.useState(false);
  const [detailedRequest, setDetailedRequest] = React.useState<Request>();
  const styles = useStyles();

  function showDetailsClick(request: Request) {
    if (request.request_headers == null) {
      getRequestDetails(request.id)
        .then((updatedRequest) => {
          if (updatedRequest) {
            updateRequest(request.id, resultId, updatedRequest);
            setDetailedRequest(updatedRequest);
            setShowDetails(true);
          } else {
            console.log('failed to update request');
          }
        })
        .catch((e) => {
          console.log(e);
        });
    } else {
      setDetailedRequest(request);
      setShowDetails(true);
    }
  }

  const headerTitles = ['Direction', 'Type', 'URL', 'Status', 'Details'];
  const requestListHeader = (
    <TableRow key="req-header">
      {headerTitles.map((title) => (
        <TableCell key={title}>
          <Typography variant="overline" className={styles.bolderText}>
            {title}
          </Typography>
        </TableCell>
      ))}
    </TableRow>
  );

  const requestListItems = requests.map((request: Request, index: number) => {
    return (
      <TableRow key={`reqRow-${index}`}>
        <TableCell>
          <Typography variant="subtitle2" component="p">
            {request.direction}
          </Typography>
        </TableCell>
        <TableCell>
          <Typography variant="subtitle2" component="p">
            {request.verb}
          </Typography>
        </TableCell>
        <TableCell className={styles.requestUrlContainer}>
          <Tooltip title={request.url} placement="bottom-start">
            <Typography variant="subtitle2" component="p" className={styles.requestUrl}>
              {request.url}
            </Typography>
          </Tooltip>
        </TableCell>
        <TableCell>
          <Typography variant="subtitle2" component="p" className={styles.bolderText}>
            {request.status}
          </Typography>
        </TableCell>
        <TableCell>
          <Button
            onClick={() => showDetailsClick(request)}
            variant="contained"
            color="secondary"
            size="small"
            disableElevation
          >
            Details
          </Button>
        </TableCell>
      </TableRow>
    );
  });

  return (
    <>
      {requests.length > 0 ? (
        <TableContainer>
          <Table className={styles.table}>
            <TableHead>{requestListHeader}</TableHead>
            <TableBody>{requestListItems}</TableBody>
          </Table>
        </TableContainer>
      ) : (
        <Box p={2}>
          <Typography variant="subtitle2" component="p">
            No Requests
          </Typography>
        </Box>
      )}
      <RequestDetailModal
        request={detailedRequest}
        modalVisible={showDetails}
        hideModal={() => setShowDetails(false)}
        usedRequest={detailedRequest?.result_id !== resultId}
      />
    </>
  );
};

export default RequestsList;
