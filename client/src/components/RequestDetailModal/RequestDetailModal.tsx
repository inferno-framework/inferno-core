import React, { FC } from 'react';
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Typography,
} from '@mui/material';
import { Request } from '~/models/testSuiteModels';
import { Input } from '@mui/icons-material';
import CustomTooltip from '~/components/_common/CustomTooltip';
import CodeBlock from './CodeBlock';
import HeaderTable from './HeaderTable';
import useStyles from './styles';
import CopyButton from '../_common/CopyButton';

export interface RequestDetailModalProps {
  request?: Request;
  modalVisible: boolean;
  hideModal: () => void;
  usedRequest: boolean;
}

const RequestDetailModal: FC<RequestDetailModalProps> = ({
  request,
  hideModal,
  modalVisible,
  usedRequest,
}) => {
  const { classes } = useStyles();
  const timestamp = request?.timestamp ? new Date(request?.timestamp) : null;

  const usedRequestIcon = (
    <CustomTooltip title="This request was performed in another test and the result is used by this test">
      <Input className={classes.inputIcon} />
    </CustomTooltip>
  );

  const requestDialogTitle = (
    <Box display="flex" className={classes.modalTitle}>
      <CustomTooltip
        title={`${request?.verb.toUpperCase() || ''} ${request?.url || ''} \u2192 ${
          request?.status || ''
        }`}
        placement="bottom-start"
      >
        <Box display="flex">
          <Box display="flex" pr={1}>
            {request?.verb.toUpperCase()}
          </Box>
          <Box pr={1} className={classes.modalTitleURL}>
            {request?.url}
          </Box>
          {request?.url && <CopyButton copyText={request.url} />}
          <Box display="flex" flexShrink={0}>
            &#8594; {request?.status}
          </Box>
        </Box>
      </CustomTooltip>
      <Box display="flex" flexGrow={1} pr={1} />
      {usedRequest && (
        <Box display="flex" flexShrink={1} flexDirection="row-reverse" px={2}>
          {usedRequestIcon}
        </Box>
      )}
    </Box>
  );

  if (request) {
    return (
      <Dialog
        open={modalVisible}
        fullWidth={true}
        maxWidth="md"
        onClose={hideModal}
        data-testid="requestDetailModal"
      >
        <DialogTitle>{requestDialogTitle}</DialogTitle>
        <Divider />
        <DialogContent>
          <Box pb={3}>
            <Typography variant="h5" component="h3" pb={timestamp ? 0 : 2}>
              Request
            </Typography>
            {timestamp && <Typography variant="overline">{timestamp.toLocaleString()}</Typography>}
            <HeaderTable headers={request.request_headers || []} />
            {request.response_body && (
              <CodeBlock
                body={request.request_body}
                headers={request.request_headers}
                title="Request Body"
              />
            )}
          </Box>
          <Box pb={3}>
            <Typography variant="h5" component="h3" pb={2}>
              Response
            </Typography>
            <HeaderTable headers={request.response_headers || []} />
            {request.response_body && (
              <CodeBlock
                body={request.response_body}
                headers={request.response_headers}
                title="Response Body"
              />
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button
            color="secondary"
            variant="contained"
            data-testid="cancel-button"
            onClick={hideModal}
            sx={{ fontWeight: 'bold' }}
          >
            Close
          </Button>
        </DialogActions>
      </Dialog>
    );
  } else {
    return null;
  }
};

export default RequestDetailModal;
