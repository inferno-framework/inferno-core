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
  TableHead,
} from '@mui/material';
import { ContentCopy, Input, SaveAlt } from '@mui/icons-material';
import { Request } from '~/models/testSuiteModels';
import { getRequestDetails } from '~/api/RequestsApi';
import RequestDetailModal from '~/components/RequestDetailModal/RequestDetailModal';
import CustomTooltip from '~/components/_common/CustomTooltip';
import { useSnackbar } from 'notistack';
import useStyles from './styles';

interface RequestListProps {
  resultId: string;
  requests: Request[];
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  view: 'report' | 'run';
}

const RequestList: FC<RequestListProps> = ({ requests, resultId, updateRequest, view }) => {
  const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  const [showDetails, setShowDetails] = React.useState(false);
  const [copySuccess, setCopySuccess] = React.useState({});
  const [detailedRequest, setDetailedRequest] = React.useState<Request>();
  const headerTitles = ['Type', 'URL', 'Status'];

  const showDetailsClick = (request: Request) => {
    if (request.request_headers === undefined) {
      getRequestDetails(request.id)
        .then((updatedRequest) => {
          if (updatedRequest) {
            updateRequest(request.id, resultId, updatedRequest);
            setDetailedRequest(updatedRequest);
            setShowDetails(true);
          } else {
            enqueueSnackbar('Failed to update request', { variant: 'error' });
          }
        })
        .catch((e: Error) => {
          enqueueSnackbar(`Error getting request details: ${e.message}`, { variant: 'error' });
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
        <CustomTooltip title="This request was performed in another test and the result is used by this test">
          <Input fontSize="small" sx={{ pr: 1 }} />
        </CustomTooltip>
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
          <Typography variant="overline" className={classes.bolderText}>
            {title}
          </Typography>
        </TableCell>
      ))}
      <TableCell
        key={'Direction'}
        role="none"
        aria-hidden="true"
        aria-label="header-request-direction"
      ></TableCell>
      {view === 'run' && (
        <TableCell
          key={'Details'}
          role="none"
          aria-hidden="true"
          aria-label="header-request-details"
        />
      )}
    </TableRow>
  );

  const requestListItems = [...requests]
    .sort((request1, request2) => request1.index - request2.index)
    .map((request: Request, index: number) => (
      <TableRow key={`reqRow-${index}`}>
        <TableCell>
          <Box display="flex">
            {renderReferenceIcon(request)}
            <Typography variant="subtitle2" component="p">
              {request.verb}
            </Typography>
          </Box>
        </TableCell>
        <TableCell className={classes.requestUrlContainer}>
          <Box display="flex" alignItems="center">
            <CustomTooltip title={request.url} placement="bottom-start">
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
            </CustomTooltip>
            <CustomTooltip
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
            </CustomTooltip>
          </Box>
        </TableCell>
        <TableCell>
          <Typography variant="subtitle2" component="p" className={classes.bolderText}>
            {request.status}
          </Typography>
        </TableCell>
        <TableCell>
          {request.direction === 'incoming' && (
            <CustomTooltip title="Direction: incoming">
              <SaveAlt />
            </CustomTooltip>
          )}
        </TableCell>
        {view === 'run' && <TableCell>{renderDetailsButton(request)}</TableCell>}
      </TableRow>
    ));

  return (
    <>
      {requests.length > 0 ? (
        <TableContainer data-testid="requests-list">
          <Table size="small" className={classes.table}>
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

export default RequestList;
