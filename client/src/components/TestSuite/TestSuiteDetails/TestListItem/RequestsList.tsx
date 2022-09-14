import React, { FC } from 'react';
import {
  Typography,
  TableRow,
  TableCell,
  Table,
  TableContainer,
  TableBody,
  Tooltip,
  TableHead,
  Box,
  Button,
} from '@mui/material';
import InputIcon from '@mui/icons-material/Input';
import { Request } from '~/models/testSuiteModels';
import RequestDetailModal from '~/components/RequestDetailModal/RequestDetailModal';
import { getRequestDetails } from '~/api/RequestsApi';
import useStyles from './styles';

interface RequestsListProps {
  resultId: string;
  requests: Request[];
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  view: 'report' | 'run';
}

const RequestsList: FC<RequestsListProps> = ({ requests, resultId, updateRequest, view }) => {
  const [showDetails, setShowDetails] = React.useState(false);
  const [detailedRequest, setDetailedRequest] = React.useState<Request>();
  const headerTitles =
    view === 'run'
      ? ['Direction', 'Type', 'URL', 'Status', 'Details']
      : ['Direction', 'Type', 'URL', 'Status'];
  const styles = useStyles();

  const showDetailsClick = (request: Request) => {
    if (request.request_headers === undefined) {
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
  };

  const renderReferenceIcon = (request: Request) => {
    if (request.result_id !== resultId) {
      return (
        <Tooltip title="This request was performed in another test and the result is used by this test">
          <InputIcon fontSize="small" sx={{ pr: 1 }} />
        </Tooltip>
      );
    }
  };

  const renderDetailsButton = (request: Request) => {
    return (
      <Button
        onClick={() => showDetailsClick(request)}
        color="secondary"
        variant="contained"
        size="small"
        disableElevation
      >
        Details
      </Button>
    );
  };

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

  const requestListItems = requests.map((request: Request, index: number) => (
    <TableRow key={`reqRow-${index}`}>
      <TableCell>
        <Typography variant="subtitle2" component="p">
          {request.direction}
        </Typography>
      </TableCell>
      <TableCell>
        <Box display="flex">
          {renderReferenceIcon(request)}
          <Typography variant="subtitle2" component="p">
            {request.verb}
          </Typography>
        </Box>
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
      {view === 'run' && <TableCell>{renderDetailsButton(request)}</TableCell>}
    </TableRow>
  ));

  return (
    <>
      {requests.length > 0 ? (
        <TableContainer>
          <Table size="small" className={styles.table}>
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
