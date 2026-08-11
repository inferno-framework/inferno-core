import React from 'react';
import { screen, getDefaultNormalizer } from '@testing-library/react';
import { renderWithProviders } from '~/test-utils';
import CodeBlock from '../CodeBlock';
import { codeResponseWithHtml, codeResponseWithJson } from '../__mocked_data__/mockData';

import { afterEach, describe, expect, it, vi } from 'vitest';

describe('CodeBlock', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders nothing when body is empty', () => {
    const { container } = renderWithProviders(<CodeBlock body="" />);
    expect(container.firstChild).toBeNull();
  });

  it('displays the code body as given if HTML', () => {
    const headers = codeResponseWithHtml.response_headers;
    const body = codeResponseWithHtml.response_body;

    renderWithProviders(<CodeBlock body={body} headers={headers} />);

    const codeBlock = screen.getByTestId('pre');
    const expected = '<html>html has newlines already</html>';
    expect(codeBlock).toHaveTextContent(expected);
  });

  it('displays pretty printed JSON if given JSON', () => {
    const headers = codeResponseWithJson.response_headers;
    const body = codeResponseWithJson.response_body;

    renderWithProviders(<CodeBlock body={body} headers={headers} />);

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

    expect(codeBlock.innerHTML).toBe(expected);
  });

  it('toggles collapse when card header is clicked', async () => {
    const body = codeResponseWithHtml.response_body;
    const headers = codeResponseWithHtml.response_headers;
    const { user } = renderWithProviders(<CodeBlock body={body} headers={headers} />);

    // Initially collapsed — pre element not visible
    expect(screen.queryByTestId('pre')).not.toBeVisible();

    await user.click(screen.getByTestId('code-block-header'));

    expect(screen.getByTestId('pre')).toBeVisible();
  });
});
