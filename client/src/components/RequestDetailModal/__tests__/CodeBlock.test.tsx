import React from 'react';
import { render, screen, getDefaultNormalizer } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import CodeBlock from '../CodeBlock';
import { codeResponseWithHTML, codeResponseWithJSON } from '../__mocked_data__/mockData';

describe('CodeBlock', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('displays the code body as given if HTML', () => {
    const headers = codeResponseWithHTML.response_headers;
    const body = codeResponseWithHTML.response_body;

    render(
      <ThemeProvider>
        <CodeBlock body={body} headers={headers} />
      </ThemeProvider>
    );

    const codeBlock = screen.getByTestId('pre');
    const expected = '<html>html has newlines already</html>';
    expect(codeBlock).toHaveTextContent(expected);
  });

  it('displays pretty printed JSON if given JSON', () => {
    const headers = codeResponseWithJSON.response_headers;
    const body = codeResponseWithJSON.response_body;

    render(
      <ThemeProvider>
        <CodeBlock body={body} headers={headers} />
      </ThemeProvider>
    );

    const codeBlock = screen.getByTestId('code', {
      normalizer: getDefaultNormalizer({ collapseWhitespace: false }),
    });
    const expected =
      '{\n' +
      '  "resourceType": "OperationOutcome",\n' +
      '  "issue": [\n' +
      '    {\n' +
      '      "severity": "error",\n' +
      '      "code": "processing",\n' +
      '      "diagnostics": "Bearer token is invalid or not supplied Supplied Bearer Token: null"\n' +
      '    }\n' +
      '  ]\n' +
      '}';

    // react-testing-library has an option on getByTestId and other queries
    // normalizer: getDefaultNormalizer({ collapseWhitespace: false })
    // but it doesn't work
    // https://github.com/testing-library/dom-testing-library/issues/883
    // so have to exit hatch to innerHTML
    expect(codeBlock.innerHTML).toBe(expected);
  });
});
