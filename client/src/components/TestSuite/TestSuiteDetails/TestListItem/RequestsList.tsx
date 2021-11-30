import React, { FC, Fragment } from 'react';
import { Button, Box } from '@mui/material';
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

  const requestListItems =
    requests.length > 0 ? (
      requests.map((request: Request, index: number) => {
        return (
          <Box key={`reqRow-${index}`} className={styles.requestRow}>
            <Box>
              <span>{request.direction}</span>
            </Box>
            <Box>{request.verb}</Box>
            <Box className={styles.requestUrl}>
              <Box>{request.url}</Box>
            </Box>
            <Box>{request.status}</Box>
            <Box>
              <Button
                onClick={() => showDetailsClick(request)}
                variant="contained"
                color="secondary"
                disableElevation
              >
                Details
              </Button>
            </Box>
          </Box>
        );
      })
    ) : (
      <Box>None</Box>
    );

  return (
    <Fragment>
      {requestListItems}
      <RequestDetailModal
        request={detailedRequest}
        modalVisible={showDetails}
        hideModal={() => setShowDetails(false)}
        usedRequest={detailedRequest?.result_id !== resultId}
      />
    </Fragment>
  );
};

export default RequestsList;
