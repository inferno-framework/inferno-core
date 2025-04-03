import React, { ChangeEvent, FC } from 'react';
import { Box, Button, Typography } from '@mui/material';
import { styled } from '@mui/material/styles';
import { FileUploadOutlined, TaskOutlined } from '@mui/icons-material';
import { useTestSessionStore } from '~/store/testSession';

export interface UploadFileButtonProps {
  onUpload: (text: string) => unknown;
}

const UploadFileButton: FC<UploadFileButtonProps> = ({ onUpload }) => {
  const viewOnly = useTestSessionStore((state) => state.viewOnly);
  const [fileName, setFileName] = React.useState<string>('');

  const uploadFile = (e: ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    const file = e.target.files[0];
    setFileName(file.name);
    const reader = new FileReader();
    reader.onload = () => {
      const text =
        typeof reader.result === 'object'
          ? JSON.stringify(reader.result)
          : reader.result?.toString();
      onUpload(text);
    };
    reader.readAsText(file);
  };

  const VisuallyHiddenInput = styled('input')({
    clip: 'rect(0 0 0 0)',
    clipPath: 'inset(50%)',
    height: 1,
    overflow: 'hidden',
    position: 'absolute',
    bottom: 0,
    left: 0,
    whiteSpace: 'nowrap',
    width: 1,
  });

  return (
    <Box display="flex" alignItems="center" sx={{ mb: 2 }}>
      <Button
        variant="contained"
        component="label"
        color="secondary"
        aria-label="file-upload"
        disabled={viewOnly}
        startIcon={<FileUploadOutlined />}
        disableElevation
        sx={{ flexShrink: 0 }}
      >
        Upload File
        <VisuallyHiddenInput type="file" onChange={(e) => uploadFile(e)} />
      </Button>
      {fileName && (
        <Box display="flex" alignItems="center" sx={{ mx: 2 }}>
          <TaskOutlined color="secondary" sx={{ mr: 1 }} />
          <Typography variant="subtitle1" sx={{ fontFamily: 'Monospace' }}>
            {fileName}
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default UploadFileButton;
