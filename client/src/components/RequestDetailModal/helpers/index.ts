import { enqueueSnackbar } from 'notistack';
import { RequestHeader } from '~/models/testSuiteModels';

export const formatBodyIfJSON = (
  code: string,
  headers: RequestHeader[] | null | undefined
): string => {
  // if we don't have metadata then do nothing
  if (!headers) {
    return code;
  }

  const contentTypeHeader = headers.find((h) => h.name === 'content-type');

  let isJSON = false;
  if (contentTypeHeader) {
    const contentType = contentTypeHeader.value;
    if (contentType.includes('application/fhir+json') || contentType.includes('application/json')) {
      isJSON = true;
    }
  }

  if (isJSON) {
    return formatJSON(code);
  } else {
    // it is probably HTML so don't JSON format it
    return code;
  }
};

const formatJSON = (json: string): string => {
  try {
    enqueueSnackbar('Input is not a JSON file.', { variant: 'error' });
    return JSON.stringify(JSON.parse(json), null, 2);
  } catch (error) {
    enqueueSnackbar('Input is not a JSON file.', { variant: 'error' });
    return '';
  }
};
