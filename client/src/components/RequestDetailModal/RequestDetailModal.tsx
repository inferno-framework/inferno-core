import React, { FC } from 'react';
import {
  Box,
  Dialog,
  DialogContent,
  DialogTitle,
  Divider,
  IconButton,
  Typography,
} from '@mui/material';
import { Request } from '~/models/testSuiteModels';
import { ContentCopy, Input } from '@mui/icons-material';
import CustomTooltip from '~/components/_common/CustomTooltip';
import CodeBlock from './CodeBlock';
import HeaderTable from './HeaderTable';
import useStyles from './styles';

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
  const [copySuccess, setCopySuccess] = React.useState(false);
  const { classes } = useStyles();
  const timestamp = request?.timestamp ? new Date(request?.timestamp) : null;

  const copyTextClick = async (text: string) => {
    await navigator.clipboard.writeText(text).then(() => {
      setCopySuccess(true);
      setTimeout(() => {
        setCopySuccess(false);
      }, 2000); // 2 second delay
    });
  };

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
          {request?.url && (
            <CustomTooltip open={copySuccess} title="Text copied!">
              <Box pr={1}>
                <IconButton color="secondary" onClick={() => void copyTextClick(request.url)}>
                  <ContentCopy fontSize="inherit" />
                </IconButton>
              </Box>
            </CustomTooltip>
          )}
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
        onClose={() => hideModal()}
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
            <CodeBlock body={request.request_body} headers={request.request_headers} />
          </Box>
          <Box pb={3}>
            <Typography variant="h5" component="h3" pb={2}>
              Response
            </Typography>
            <HeaderTable headers={request.response_headers || []} />
            <CodeBlock body={request.response_body} headers={request.response_headers} />
          </Box>
        </DialogContent>
      </Dialog>
    );
  } else {
    return null;
  }
};

export default RequestDetailModal;
