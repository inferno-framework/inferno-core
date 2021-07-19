import React, { FC, Fragment } from 'react';
import { Table, TableBody, TableRow, TableCell, Button, Tooltip } from '@material-ui/core';
import { Request } from 'models/testSuiteModels';
import { getRequestDetails } from 'api/infernoApiService';
import RequestDetailModal from 'components/RequestDetailModal/RequestDetailModal';
import InputIcon from '@material-ui/icons/Input';

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

  const usedRequestIcon = (
    <Tooltip title="This request was performed in another test and the result is used by this test">
      <InputIcon />
    </Tooltip>
  );
  const requestListItems =
    requests.length > 0 ? (
      requests.map((request: Request, index: number) => {
        const usedRequest = request.result_id !== resultId;
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
              {usedRequest ? usedRequestIcon : null}
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
      />
    </Fragment>
  );
};

export default RequestsList;
