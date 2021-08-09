import React, { FC, Fragment } from 'react';
import { Table, TableBody, TableRow, TableCell, Button } from '@material-ui/core';
import { Request } from 'models/testSuiteModels';
import RequestDetailModal from 'components/RequestDetailModal/RequestDetailModal';
import { getRequestDetails } from 'api/RequestsApi';

interface RequestsListProps {
  resultId: string;
  requests: Request[];
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
}

const RequestsList: FC<RequestsListProps> = ({ requests, resultId, updateRequest }) => {
  const [showDetails, setShowDetails] = React.useState(false);
  const [detailedRequest, setDetailedRequest] = React.useState<Request>();

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
          <TableRow key={`msgRow-${index}`}>
            <TableCell>
              <span>{request.direction}</span>
            </TableCell>
            <TableCell>{request.verb}</TableCell>
            <TableCell>{request.url}</TableCell>
            <TableCell>{request.status}</TableCell>
            <TableCell>
              <Button
                onClick={() => showDetailsClick(request)}
                variant="contained"
                color="secondary"
                disableElevation
              >
                Details
              </Button>
            </TableCell>
          </TableRow>
        );
      })
    ) : (
      <TableRow key={`msgRow-none`}>
        <TableCell>None</TableCell>
      </TableRow>
    );

  return (
    <Fragment>
      <Table>
        <TableBody>{requestListItems}</TableBody>
      </Table>
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
