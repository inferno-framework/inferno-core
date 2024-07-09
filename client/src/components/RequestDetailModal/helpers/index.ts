import { enqueueSnackbar } from 'notistack';
import { RequestHeader } from '~/models/testSuiteModels';

export const formatBodyIfJson = (
  code: string,
  headers: RequestHeader[] | null | undefined
): string => {
  // if we don't have metadata then do nothing
  if (!headers) {
    return code;
  }

  const contentTypeHeader = headers.find((h) => h.name === 'content-type');

  let isJson = false;
  if (contentTypeHeader) {
    const contentType = contentTypeHeader.value;
    if (contentType.includes('application/fhir+json') || contentType.includes('application/json')) {
      isJson = true;
    }
  }

  if (isJson) {
    return formatJson(code);
  } else {
    // it is probably HTML so don't JSON format it
    return code;
  }
};

const formatJson = (json: string): string => {
  try {
    return JSON.stringify(JSON.parse(json), null, 2);
  } catch (error) {
    enqueueSnackbar('Input is not a JSON file.', { variant: 'error' });
    return '';
  }
};
