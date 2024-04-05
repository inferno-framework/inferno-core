import React, { ChangeEvent, FC } from 'react';
import { Button } from '@mui/material';
import { FileUploadOutlined } from '@mui/icons-material';

export interface UploadFileButtonProps {
  onUpload: (text: string) => unknown;
}

const UploadFileButton: FC<UploadFileButtonProps> = ({ onUpload }) => {
  const uploadFile = (e: ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    const file = e.target.files[0];
    const reader = new FileReader();
    reader.onload = () => {
      const text = reader.result?.toString() || '';
      onUpload(text);
    };
    reader.readAsText(file);
  };

  return (
    <Button
      variant="contained"
      component="label"
      color="secondary"
      aria-label="file-upload"
      startIcon={<FileUploadOutlined />}
      sx={{ mb: 2 }}
    >
      Upload File
      <input style={{ display: 'none' }} type="file" hidden onChange={(e) => uploadFile(e)} />
    </Button>
  );
};

export default UploadFileButton;
