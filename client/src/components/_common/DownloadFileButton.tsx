import React, { FC } from 'react';
import { Button } from '@mui/material';
import { FileDownloadOutlined } from '@mui/icons-material';

export interface DownloadFileButtonProps {
  fileName: string;
  fileType: string;
}

const DownloadFileButton: FC<DownloadFileButtonProps> = ({ fileName, fileType }) => {
  const downloadFile = () => {
    const downloadLink = document.createElement('a');
    const file = new Blob(
      [(document.getElementById(`${fileType}-serial-input`) as HTMLInputElement)?.value],
      {
        type: 'text/plain',
      },
    );
    downloadLink.href = URL.createObjectURL(file);
    downloadLink.download = `${fileName}.${fileType}`;
    document.body.appendChild(downloadLink); // Required for this to work in FireFox
    downloadLink.click();
  };

  return (
    <Button
      variant="contained"
      component="label"
      color="secondary"
      aria-label="file-download"
      startIcon={<FileDownloadOutlined />}
      disableElevation
      onClick={downloadFile}
      sx={{ mb: 4 }}
    >
      Download File
    </Button>
  );
};

export default DownloadFileButton;
