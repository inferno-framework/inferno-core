import {
  Box,
  Dialog,
  DialogContent,
  DialogTitle,
  Divider,
  Tooltip,
  Typography,
} from '@mui/material';
import { Request } from 'models/testSuiteModels';
import React, { FC } from 'react';
import CodeBlock from './CodeBlock';
import HeaderTable from './HeaderTable';
import useStyles from './styles';
import InputIcon from '@mui/icons-material/Input';

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
  const styles = useStyles();

  const usedRequestIcon = (
    <Tooltip title="This request was performed in another test and the result is used by this test">
      <InputIcon className={styles.inputIcon} />
    </Tooltip>
  );

  const requestDialogTitle = (
    <Tooltip
      title={`${request?.verb.toUpperCase() || ''} ${request?.url || ''} \u2192 ${
        request?.status || ''
      }`}
      placement="bottom-start"
    >
      <Box className={styles.modalTitle}>
        <Box className={styles.modalTitleContainerShrink}>{request?.verb.toUpperCase()}</Box>
        <Box className={styles.modalTitleURL}>{request?.url}</Box>
        <Box className={styles.modalTitleContainerNoShrink}>&#8594; {request?.status}</Box>
        {usedRequest && <Box className={styles.modalTitleIcon}>{usedRequestIcon}</Box>}
      </Box>
    </Tooltip>
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
          <div className={styles.section}>
            <Typography variant="h5" component="h3" className={styles.sectionHeader}>
              Request
            </Typography>
            <HeaderTable headers={request.request_headers || []} />
            <CodeBlock body={request.request_body} />
          </div>
          <div className={styles.section}>
            <Typography variant="h5" component="h3" className={styles.sectionHeader}>
              Response
            </Typography>
            <HeaderTable headers={request.response_headers || []} />
            <CodeBlock body={request.response_body} />
          </div>
        </DialogContent>
      </Dialog>
    );
  } else {
    return null;
  }
};

export default RequestDetailModal;
