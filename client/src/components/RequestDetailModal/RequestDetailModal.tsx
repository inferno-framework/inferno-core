import {
  Dialog,
  DialogContent,
  DialogTitle,
  Divider,
  Tooltip,
  Typography,
} from '@material-ui/core';
import { Request } from 'models/testSuiteModels';
import React, { FC } from 'react';
import CodeBlock from './CodeBlock';
import HeaderTable from './HeaderTable';
import useStyles from './styles';
import InputIcon from '@material-ui/icons/Input';

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

  if (request) {
    return (
      <Dialog open={modalVisible} fullWidth={true} maxWidth="md" onClose={() => hideModal()}>
        <DialogTitle className={styles.modalTitle} disableTypography={true}>
          {request.verb.toUpperCase()} {request.url} &#8594; {request.status}
          {usedRequest ? usedRequestIcon : null}
        </DialogTitle>
        <Divider />
        <DialogContent>
          <div className={styles.section}>
            <Typography variant="h5" className={styles.sectionHeader}>
              Request
            </Typography>
            <HeaderTable headers={request.request_headers || []} />
            <CodeBlock body={request.request_body} />
          </div>
          <div className={styles.section}>
            <Typography variant="h5" className={styles.sectionHeader}>
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
