import React, { FC } from 'react';
import {
  Box,
  Button,
  IconButton,
  Typography,
  TableRow,
  TableCell,
  Table,
  TableContainer,
  TableBody,
  Tooltip,
  TableHead,
} from '@mui/material';
import InputIcon from '@mui/icons-material/Input';
import { Request } from '~/models/testSuiteModels';
import RequestDetailModal from '~/components/RequestDetailModal/RequestDetailModal';
import { getRequestDetails } from '~/api/RequestsApi';
import useStyles from './styles';
import { ContentCopy } from '@mui/icons-material';

interface RequestsListProps {
  resultId: string;
  requests: Request[];
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  view: 'report' | 'run';
}

const RequestsList: FC<RequestsListProps> = ({ requests, resultId, updateRequest, view }) => {
  const [showDetails, setShowDetails] = React.useState(false);
  const [copySuccess, setCopySuccess] = React.useState({});
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

  const copyTextClick = async (text: string) => {
    await navigator.clipboard.writeText(text).then(() => {
      setCopySuccess({ ...copySuccess, [text]: true });
      setTimeout(() => {
        // Reset map instead of setting false to avoid async bug
        setCopySuccess({});
      }, 2000); // 2 second delay
    });
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

  const requestListItems = [...requests]
    .sort((request1, request2) => request1.index - request2.index)
    .map((request: Request, index: number) => (
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
          <Box display="flex" alignItems="center">
            <Tooltip title={request.url} placement="bottom-start">
              <Typography
                variant="subtitle2"
                component="p"
                sx={
                  view === 'run'
                    ? {
                        overflow: 'hidden',
                        maxHeight: '1.5em',
                        wordBreak: 'break-all',
                        display: '-webkit-box',
                        WebkitBoxOrient: 'vertical',
                        WebkitLineClamp: '1',
                      }
                    : {}
                }
              >
                {request.url}
              </Typography>
            </Tooltip>
            <Tooltip
              open={copySuccess[request.url as keyof typeof copySuccess] || false}
              title="Text copied!"
              sx={
                view === 'report'
                  ? {
                      display: 'none',
                      '@media print': {
                        display: 'none',
                      },
                    }
                  : {}
              }
            >
              <IconButton
                size="small"
                color="secondary"
                onClick={() => void copyTextClick(request.url)}
              >
                <ContentCopy fontSize="inherit" />
              </IconButton>
            </Tooltip>
          </Box>
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
        <TableContainer data-testid="requests-list">
          <Table size="small" className={styles.table}>
            <TableHead>{requestListHeader}</TableHead>
            <TableBody>{requestListItems}</TableBody>
          </Table>
        </TableContainer>
      ) : (
        <Box p={2} data-testid="requests-list">
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
        data-testid="requests-detail-modal"
      />
    </>
  );
};

export default RequestsList;
